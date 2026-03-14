import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_provider.dart';
import '../../widgets/notification_bell.dart';
import '../profile_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  double _totalSpent = 0;
  double _totalReceived = 0;
  double _totalPaid = 0;
  double _netBalance = 0;
  bool _isLoading = true;
  bool _isSearchOpen = false;
  String _selectedTypeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final provider = context.read<AppProvider>();
      final debts = await provider.getMyDebts();

      // ── Debt / Settlement entries ──────────────────────────────────────────
      final debtEntries = debts.map((d) {
        final bool isFrom = (d['from_user_id'] as String?) == currentUserId;
        final String otherName = isFrom
            ? ((d['to_user'] as Map?)?['name'] as String?) ?? 'Unknown'
            : ((d['from_user'] as Map?)?['name'] as String?) ?? 'Unknown';
        final amount = (d['amount'] as num?)?.toDouble() ?? 0.0;
        return {
          'id': d['id'],
          'type': d['status'] == 'settled' ? 'Settlement' : 'Debt',
          'description': (d['expense'] as Map?)?['description'] ?? 'Expense',
          'group': (d['group'] as Map?)?['name'] ?? 'Unknown Group',
          'fromTo': otherName,
          'amount': isFrom
              ? '-PHP ${amount.toStringAsFixed(2)}'
              : '+PHP ${amount.toStringAsFixed(2)}',
          'status': d['status'] ?? 'pending',
          'date': (d['created_at'] as String?)?.split('T').first ?? '',
          '_rawAmount': amount,
          '_isFrom': isFrom,
          '_sortDate': (d['created_at'] as String?) ?? '',
        };
      }).toList();

      // ── Partial Payment entries ────────────────────────────────────────────
      final paymentsData = await supabase
          .from('debt_payments')
          .select('''
        id, amount, payment_method, created_at,
        debt:debts (
          id, from_user_id, to_user_id,
          from_user:profiles!debts_from_user_id_fkey ( id, name ),
          to_user:profiles!debts_to_user_id_fkey ( id, name ),
          group:groups ( id, name ),
          expense:expenses ( id, description )
        )
      ''')
          .eq('paid_by', currentUserId)
          .order('created_at', ascending: false);

      final paymentEntries = (paymentsData as List).map((p) {
        final debt = p['debt'] as Map?;
        final bool isFrom = (debt?['from_user_id'] as String?) == currentUserId;
        final String otherName = isFrom
            ? ((debt?['to_user'] as Map?)?['name'] as String?) ?? 'Unknown'
            : ((debt?['from_user'] as Map?)?['name'] as String?) ?? 'Unknown';
        final paidAmount = (p['amount'] as num?)?.toDouble() ?? 0.0;
        return {
          'id': p['id'],
          'type': 'Partial Payment',
          'description':
              ((debt?['expense'] as Map?)?['description'] as String?) ??
              'Expense',
          'group':
              ((debt?['group'] as Map?)?['name'] as String?) ?? 'Unknown Group',
          'fromTo': otherName,
          'amount': '-PHP ${paidAmount.toStringAsFixed(2)}',
          'status': 'paid',
          'payment_method': (p['payment_method'] as String?) ?? '',
          'date': (p['created_at'] as String?)?.split('T').first ?? '',
          '_rawAmount': paidAmount,
          '_isFrom': true,
          '_sortDate': (p['created_at'] as String?) ?? '',
        };
      }).toList();

      // ── Merge and sort by date descending ─────────────────────────────────
      final all = [...debtEntries, ...paymentEntries];
      all.sort(
        (a, b) =>
            (b['_sortDate'] as String).compareTo(a['_sortDate'] as String),
      );

      // ── Totals ────────────────────────────────────────────────────────────
      double spent = 0, received = 0;
      for (final d in debts) {
        final amount = (d['amount'] as num?)?.toDouble() ?? 0.0;
        final bool isFrom = (d['from_user_id'] as String?) == currentUserId;
        if (isFrom) spent += amount;
        if (!isFrom && d['status'] == 'settled') received += amount;
      }
      // Total paid = actual cash paid out via debt_payments
      double paid = 0;
      for (final p in paymentsData as List) {
        paid += (p['amount'] as num?)?.toDouble() ?? 0.0;
      }

      if (mounted) {
        setState(() {
          _allTransactions = all;
          _filteredTransactions = all;
          _totalSpent = spent;
          _totalReceived = received;
          _totalPaid = paid;
          _netBalance = received - spent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load transactions: $e',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    final search = _searchController.text.toLowerCase();
    final status = _statusController.text.toLowerCase();
    final group = _groupController.text.toLowerCase();
    final startDate = _startDateController.text.trim();
    final endDate = _endDateController.text.trim();

    setState(() {
      _filteredTransactions = _allTransactions.where((t) {
        // Live search: description, fromTo, group
        if (search.isNotEmpty &&
            !t['description'].toString().toLowerCase().contains(search) &&
            !t['fromTo'].toString().toLowerCase().contains(search) &&
            !t['group'].toString().toLowerCase().contains(search)) {
          return false;
        }
        if (_selectedTypeFilter != 'All' &&
            t['type'].toString() != _selectedTypeFilter) {
          return false;
        }
        if (status.isNotEmpty &&
            !t['status'].toString().toLowerCase().contains(status)) {
          return false;
        }
        if (group.isNotEmpty &&
            !t['group'].toString().toLowerCase().contains(group)) {
          return false;
        }
        if (startDate.isNotEmpty &&
            t['date'].toString().compareTo(startDate) < 0) {
          return false;
        }
        if (endDate.isNotEmpty && t['date'].toString().compareTo(endDate) > 0) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    _typeController.dispose();
    _statusController.dispose();
    _groupController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // ─── Type icon helper ───────────────────────────────────────────────────────
  ({IconData icon, Color bg, Color fg}) _typeStyle(String type) {
    switch (type) {
      case 'Settlement':
        return (
          icon: Icons.check_circle_outline,
          bg: const Color(0xFFD4F2E3),
          fg: const Color(0xFF27A862),
        );
      case 'Partial Payment':
        return (
          icon: Icons.credit_card_outlined,
          bg: const Color(0xFFD6EAF8),
          fg: const Color(0xFF1A73E8),
        );
      default: // Debt
        return (
          icon: Icons.account_balance_wallet_outlined,
          bg: const Color(0xFFFFF3E0),
          fg: const Color(0xFFF57C00),
        );
    }
  }

  // ─── Status colors helper ───────────────────────────────────────────────────
  ({Color bg, Color fg}) _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'settled':
        return (bg: const Color(0xFFD4F2E3), fg: const Color(0xFF27A862));
      case 'paid':
        return (bg: const Color(0xFFD6EAF8), fg: const Color(0xFF1A73E8));
      case 'pending':
        return (bg: const Color(0xFFFFF3E0), fg: const Color(0xFFF57C00));
      default:
        return (bg: const Color(0xFFF0F0F0), fg: const Color(0xFF5A5A5A));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6FAFC), Color(0xFFDCF2FF), Color(0xFFB4E4FF)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 28,
                ),
                child: _buildHeader(profile),
              ),

              // ── Title + Search bar ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Transactions',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF003CC1),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSearchOpen = !_isSearchOpen;
                              if (!_isSearchOpen) _searchController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _isSearchOpen ? Icons.close : Icons.search,
                              color: const Color(0xFF038AFF),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isSearchOpen) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search description, person, group…',
                          hintStyle: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF9E9E9E),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFDDDDDD),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF038AFF),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Type filter chips ───────────────────────────────────────
              _buildTypeChips(),
              const SizedBox(height: 14),

              // ── Summary row ─────────────────────────────────────────────
              _buildSummaryRow(),
              const SizedBox(height: 12),

              // ── Transaction list in a white card ────────────────────────
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: RefreshIndicator(
                    onRefresh: _loadTransactions,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredTransactions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'No transactions found',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: const Color(0xFF9E9E9E),
                                ),
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 24,
                              ),
                              itemCount: _filteredTransactions.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 80,
                                endIndent: 24,
                                color: Color(0xFFEEEEEE),
                              ),
                              itemBuilder: (ctx, i) => _buildTransactionTile(
                                _filteredTransactions[i],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── header (mirrors dashboard layout) ──────────────────────────────────────

  Widget _buildHeader(Map<String, dynamic>? profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF003CC1), Color(0xFF038AFF), Color(0xFF01A7FF)],
          ).createShader(bounds),
          child: Text(
            'SplitSmart',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Row(
          children: [
            const NotificationBell(),
            const SizedBox(width: 12),

            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [Color(0xFF0254D8), Color(0xFF003CC1)],
                    center: Alignment.center,
                    radius: 0.8,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: (profile?['avatar_url'] as String?) != null
                      ? Image.network(
                          profile!['avatar_url'] as String,
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              profile['name'] != null
                                  ? (profile['name'] as String)
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : 'M',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            profile?['name'] != null
                                ? (profile!['name'] as String)
                                      .substring(0, 1)
                                      .toUpperCase()
                                : 'M',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  // ─── Type filter chips ───────────────────────────────────────────────────────

  Widget _buildTypeChips() {
    const types = ['All', 'Debt', 'Settlement', 'Partial Payment'];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: types.map((type) {
          final selected = _selectedTypeFilter == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTypeFilter = type);
                _applyFilters();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF003CC1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF003CC1)
                        : const Color(0xFFDDDDDD),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF003CC1).withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  type,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF5A5A5A),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Summary row ─────────────────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    final summaries = [
      {
        'label': 'Spent',
        'value': '₱${_totalSpent.toStringAsFixed(2)}',
        'color': const Color(0xFFE53935),
      },
      {
        'label': 'Received',
        'value': '₱${_totalReceived.toStringAsFixed(2)}',
        'color': const Color(0xFF27A862),
      },
      {
        'label': 'Paid',
        'value': '₱${_totalPaid.toStringAsFixed(2)}',
        'color': const Color(0xFFF57C00),
      },
      {
        'label': 'Net',
        'value': '₱${_netBalance.toStringAsFixed(2)}',
        'color': const Color(0xFF7B1FA2),
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: summaries.asMap().entries.map((e) {
          final s = e.value;
          final isLast = e.key == summaries.length - 1;
          return Expanded(
            child: Container(
              margin: isLast
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['label'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s['value'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: s['color'] as Color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Transaction list tile ───────────────────────────────────────────────────

  Widget _buildTransactionTile(Map<String, dynamic> t) {
    final style = _typeStyle(t['type'] as String);
    final isFrom = t['_isFrom'] as bool;
    final amtColor = isFrom ? const Color(0xFFE53935) : const Color(0xFF27A862);

    return InkWell(
      onTap: () => _showTransactionDetail(t),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(style.icon, color: style.fg, size: 22),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['description'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${t['type']} · ${t['fromTo']}',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: const Color(0xFF9E9E9E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  t['amount'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: amtColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  t['date'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Transaction detail bottom sheet ────────────────────────────────────────

  void _showTransactionDetail(Map<String, dynamic> t) {
    final style = _typeStyle(t['type'] as String);
    final statusStyle = _statusStyle(t['status'] as String);
    final isFrom = t['_isFrom'] as bool;
    final amtColor = isFrom ? const Color(0xFFE53935) : const Color(0xFF27A862);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: 32,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF7FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),

            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(style.icon, color: style.fg, size: 28),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              t['description'] as String,
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003CC1),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: statusStyle.bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                t['status'] as String,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusStyle.fg,
                ),
              ),
            ),
            const SizedBox(height: 22),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _detailRow(
                    'Amount',
                    t['amount'] as String,
                    valueColor: amtColor,
                  ),
                  _divider(),
                  _detailRow('Type', t['type'] as String),
                  _divider(),
                  _detailRow('Group', t['group'] as String),
                  _divider(),
                  _detailRow('From / To', t['fromTo'] as String),
                  _divider(),
                  _detailRow(
                    'Date',
                    t['date'] as String,
                    isLast: (t['payment_method'] as String?)?.isEmpty != false,
                  ),
                  if ((t['payment_method'] as String?)?.isNotEmpty == true) ...[
                    _divider(),
                    _detailRow(
                      'Payment Method',
                      t['payment_method'] as String,
                      isLast: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 26),

            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF038AFF), Color(0xFF003CC1)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'Done',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: const Color(0xFF9E9E9E),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
    height: 1,
    indent: 18,
    endIndent: 18,
    color: Color(0xFFEEEEEE),
  );
}
