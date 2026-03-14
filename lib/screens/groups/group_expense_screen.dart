import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../providers/app_provider.dart';
import '../dashboard_screen.dart';
import '../profile_screen.dart';
import 'add_expense_screen.dart';
import 'add_member_screen.dart';

class GroupExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupExpenseScreen({super.key, required this.group});

  @override
  State<GroupExpenseScreen> createState() => _GroupExpenseScreenState();
}

class _GroupExpenseScreenState extends State<GroupExpenseScreen> {
  int _selectedIndex = 1;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  List<Map<String, dynamic>> _expenses = [];
  bool _loadingExpenses = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _loadingExpenses = true);
    try {
      final provider = context.read<AppProvider>();
      final groupId = widget.group['id'] as String;
      final data = await provider.getGroupExpenses(groupId);
      if (mounted) setState(() => _expenses = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading expenses: $e',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingExpenses = false);
    }
  }

  String get _groupId => widget.group['id'] as String;
  String get _groupName =>
      widget.group['name'] ?? widget.group['groupName'] ?? 'Group';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6FAFC), Color(0xFFDCF2FF), Color(0xFFB4E4FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 32,
                ),
                child: _buildHeader(context, profile),
              ),

              _buildGroupInfoSection(context),

              Expanded(child: _buildExpenseList(context)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _selectedIndex,
        height: 65.0,
        items: <Widget>[
          Icon(
            Icons.dashboard_outlined,
            size: 30,
            color: _selectedIndex == 0
                ? const Color(0xFF038AFF)
                : const Color(0xFF9E9E9E),
          ),
          Icon(
            Icons.group_outlined,
            size: 30,
            color: _selectedIndex == 1
                ? const Color(0xFF038AFF)
                : const Color(0xFF9E9E9E),
          ),
          Icon(
            Icons.article_outlined,
            size: 30,
            color: _selectedIndex == 2
                ? const Color(0xFF038AFF)
                : const Color(0xFF9E9E9E),
          ),
          Icon(
            Icons.history_outlined,
            size: 30,
            color: _selectedIndex == 3
                ? const Color(0xFF038AFF)
                : const Color(0xFF9E9E9E),
          ),
          Icon(
            Icons.person_outline,
            size: 30,
            color: _selectedIndex == 4
                ? const Color(0xFF038AFF)
                : const Color(0xFF9E9E9E),
          ),
        ],
        color: Colors.white,
        buttonBackgroundColor: Colors.white,
        backgroundColor: const Color(0xFFB4E4FF),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  DashboardScreen(initialIndex: index),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
            (route) => false,
          );
        },
        letIndexChange: (index) => true,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic>? profile) {
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  230,
                  245,
                  255,
                ).withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF038AFF),
                size: 22,
              ),
            ),
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
                                  ? ((profile['name'] as String).isNotEmpty
                                        ? (profile['name'] as String)
                                              .substring(0, 1)
                                              .toUpperCase()
                                        : '?')
                                  : '?',
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
                                ? ((profile!['name'] as String).isNotEmpty
                                      ? (profile['name'] as String)
                                            .substring(0, 1)
                                            .toUpperCase()
                                      : '?')
                                : '?',
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

  Widget _buildGroupInfoSection(BuildContext context) {
    return Column(
      children: [
        Container(height: 1, color: Colors.white.withOpacity(0.5)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _groupName,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003CC1),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showMembersSheet(context),
                    icon: const Icon(
                      Icons.group_outlined,
                      color: Color(0xFF003CC1),
                      size: 26,
                    ),
                    tooltip: 'View members',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionButton(
                      context,
                      label: 'Add Member',
                      icon: Icons.person_add_outlined,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddMemberScreen(groupId: _groupId),
                          ),
                        );
                        if (result == true && mounted) {
                          context.read<AppProvider>().refreshGroups();
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildActionButton(
                      context,
                      label: 'New Expense',
                      icon: Icons.add_circle_outline,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddExpenseScreen(
                              groupId: _groupId,
                              groupName: _groupName,
                            ),
                          ),
                        );
                        if (result == true && mounted) {
                          _loadExpenses();
                          context.read<AppProvider>().init();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: Colors.white.withOpacity(0.5)),
      ],
    );
  }

  void _showMembersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _MembersBottomSheet(groupId: _groupId, groupName: _groupName),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003CC1), Color(0xFF038AFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003CC1).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context) {
    if (_loadingExpenses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Color(0xFF9E9E9E),
            ),
            const SizedBox(height: 12),
            Text(
              'No expenses yet',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "New Expense" to add one',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExpenses,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final expense = _expenses[index];
          final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
          final splits = (expense['splits'] as List?) ?? [];
          final memberCount = splits.isNotEmpty ? splits.length : 1;
          final perPerson = memberCount > 0 ? amount / memberCount : amount;
          final payerName = (expense['paid_by'] as Map?)?['name'] ?? 'Unknown';
          final date = expense['date'] ?? expense['created_at'] ?? '';

          final paidById = expense['paid_by_user_id'] as String? ?? '';
          final currentUserId =
              context.read<AppProvider>().profile?['id'] as String? ?? '';
          final receiptUrl = expense['receipt_url'] as String?;
          return _buildExpenseCard(
            id: expense['id'],
            title: expense['description'] ?? 'Expense',
            amount: amount,
            payor: payerName,
            perPerson: perPerson,
            splitBetween: '$memberCount member(s)',
            date: date,
            paidByUserId: paidById,
            currentUserId: currentUserId,
            receiptUrl: receiptUrl,
          );
        },
      ),
    );
  }

  void _showExpenseDetail({
    required String title,
    required double amount,
    required String payor,
    required double perPerson,
    required String splitBetween,
    required String date,
    String? receiptUrl,
  }) {
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
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF003CC1),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003CC1),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '₱${amount.toStringAsFixed(2)}',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF27A862),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                children: [
                  _buildDetailRow('Paid by', payor),
                  const Divider(height: 20, color: Color(0xFFF0F0F0)),
                  _buildDetailRow(
                    'Per person',
                    '₱${perPerson.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 20, color: Color(0xFFF0F0F0)),
                  _buildDetailRow('Split between', splitBetween),
                  const Divider(height: 20, color: Color(0xFFF0F0F0)),
                  _buildDetailRow('Date', date),
                  if (receiptUrl != null) ...[
                    const Divider(height: 20, color: Color(0xFFF0F0F0)),
                    _buildDetailRow('Receipt', 'View attached'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF757575),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseCard({
    required String id,
    required String title,
    required double amount,
    required String payor,
    required double perPerson,
    required String splitBetween,
    required String date,
    required String paidByUserId,
    required String currentUserId,
    String? receiptUrl,
  }) {
    final canDelete = paidByUserId == currentUserId && paidByUserId.isNotEmpty;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () => _showExpenseDetail(
          title: title,
          amount: amount,
          payor: payor,
          perPerson: perPerson,
          splitBetween: splitBetween,
          date: date,
          receiptUrl: receiptUrl,
        ),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF003CC1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Paid by $payor · $splitBetween',
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
                    '₱${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF27A862),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: canDelete
                    ? () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              'Delete Expense',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to delete "$title"?',
                              style: GoogleFonts.montserrat(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.montserrat(),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  'Delete',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          await context.read<AppProvider>().deleteExpense(id);
                          _loadExpenses();
                        }
                      }
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    color: canDelete
                        ? const Color(0xFFEF5350)
                        : const Color(0xFFCCCCCC),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Members Bottom Sheet ────────────────────────────────────────────────────

class _MembersBottomSheet extends StatefulWidget {
  final String groupId;
  final String groupName;

  const _MembersBottomSheet({required this.groupId, required this.groupName});

  @override
  State<_MembersBottomSheet> createState() => _MembersBottomSheetState();
}

class _MembersBottomSheetState extends State<_MembersBottomSheet> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final provider = context.read<AppProvider>();
      final group = await provider.getGroup(widget.groupId);
      final raw = (group['members'] as List?) ?? [];

      final currentUserId = provider.profile?['id'] as String?;
      final currentUserName = provider.profile?['name'] as String?;

      if (mounted) {
        setState(() {
          _members = raw.map((e) {
            final entry = Map<String, dynamic>.from(e as Map);
            // Patch current user's name when profiles.name is null in DB
            if (entry.containsKey('user') && entry['user'] is Map) {
              final user = Map<String, dynamic>.from(entry['user'] as Map);
              if (user['id'] == currentUserId &&
                  (user['name'] == null ||
                      (user['name'] as String).trim().isEmpty)) {
                user['name'] = currentUserName;
                entry['user'] = user;
              }
            } else if (entry['id'] == currentUserId &&
                (entry['name'] == null ||
                    (entry['name'] as String).trim().isEmpty)) {
              entry['name'] = currentUserName;
            }
            return entry;
          }).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.group_outlined,
                color: Color(0xFF003CC1),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                _loading ? 'Members' : 'Members (${_members.length})',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003CC1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.groupName,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF7A7A7A),
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No members found',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _members.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final raw = _members[i];
                  final member = (raw.containsKey('user') && raw['user'] is Map)
                      ? raw['user'] as Map<String, dynamic>
                      : raw;

                  final name =
                      (member['name'] as String?)?.trim().isNotEmpty == true
                      ? member['name'] as String
                      : 'Unknown';
                  final email = (member['email'] as String?) ?? '';
                  final avatarUrl = member['avatar_url'] as String?;
                  final initial = name.isNotEmpty
                      ? name.substring(0, 1).toUpperCase()
                      : '?';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [Color(0xFF0254D8), Color(0xFF003CC1)],
                              center: Alignment.center,
                              radius: 0.8,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: avatarUrl != null
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        initial,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2C2C2C),
                                ),
                              ),
                              if (email.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: const Color(0xFF8B8B8B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
