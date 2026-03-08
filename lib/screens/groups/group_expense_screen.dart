import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../providers/app_provider.dart';
import '../dashboard_screen.dart';
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

  // ADDED - load real expenses from Supabase
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
            content: Text('Error loading expenses: $e', style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingExpenses = false);
    }
  }

  String get _groupId => widget.group['id'] as String;
  String get _groupName => widget.group['name'] ?? widget.group['groupName'] ?? 'Group';

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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                child: _buildHeader(context, profile),
              ),

              // Group Info Section with Buttons
              _buildGroupInfoSection(context),

              // Expense Cards List
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
            color: _selectedIndex == 0 ? const Color(0xFF038AFF) : const Color(0xFF9E9E9E),
          ),
          Icon(
            Icons.group_outlined,
            size: 30,
            color: _selectedIndex == 1 ? const Color(0xFF038AFF) : const Color(0xFF9E9E9E),
          ),
          Icon(
            Icons.article_outlined,
            size: 30,
            color: _selectedIndex == 2 ? const Color(0xFF038AFF) : const Color(0xFF9E9E9E),
          ),
          Icon(
            Icons.history_outlined,
            size: 30,
            color: _selectedIndex == 3 ? const Color(0xFF038AFF) : const Color(0xFF9E9E9E),
          ),
          Icon(
            Icons.person_outline,
            size: 30,
            color: _selectedIndex == 4 ? const Color(0xFF038AFF) : const Color(0xFF9E9E9E),
          ),
        ],
        color: Colors.white,
        buttonBackgroundColor: Colors.white,
        backgroundColor: const Color(0xFFB4E4FF),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen(initialIndex: 0)),
              (route) => false,
            );
          } else {
            setState(() => _selectedIndex = index);
          }
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
            style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 230, 245, 255).withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.notifications_outlined, color: Color(0xFF038AFF), size: 22),
            ),
            const SizedBox(width: 12),
            Container(
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
              child: Center(
                child: Text(
                  // FIXED - use 'name' not 'full_name'
                  profile?['name'] != null ? (profile!['name'] as String).substring(0, 1).toUpperCase() : '?',
                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
              // FIXED - use 'name' field
              Text(
                _groupName,
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003CC1),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildActionButton(
                    context,
                    label: 'Add Member',
                    icon: Icons.person_add_outlined,
                    onTap: () async {
                      // FIXED - pass groupId
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddMemberScreen(groupId: _groupId)),
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
                      // FIXED - pass groupId and groupName
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddExpenseScreen(groupId: _groupId, groupName: _groupName),
                        ),
                      );
                      if (result == true && mounted) {
                        _loadExpenses(); // refresh expense list
                        context.read<AppProvider>().init(); // refresh dashboard
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(height: 1, color: Colors.white.withOpacity(0.5)),
      ],
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
        gradient: const LinearGradient(colors: [Color(0xFF003CC1), Color(0xFF038AFF)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: const Color(0xFF003CC1).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4)),
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
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
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
            const Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF9E9E9E)),
            const SizedBox(height: 12),
            Text('No expenses yet', style: GoogleFonts.montserrat(fontSize: 14, color: const Color(0xFF9E9E9E))),
            const SizedBox(height: 4),
            Text(
              'Tap "New Expense" to add one',
              style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF9E9E9E)),
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
          final memberCount = expense['member_count'] ?? 1;
          final perPerson = memberCount > 0 ? amount / memberCount : amount;
          final payerName = (expense['profiles'] as Map?)?['name'] ?? 'Unknown';
          final date = expense['date'] ?? expense['created_at'] ?? '';

          return _buildExpenseCard(
            id: expense['id'],
            title: expense['description'] ?? 'Expense',
            amount: amount,
            payor: payerName,
            perPerson: perPerson,
            splitBetween: '$memberCount member(s)',
            date: date,
          );
        },
      ),
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF038AFF).withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003CC1),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₱${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF66BB6A),
                    ),
                  ),
                ],
              ),
              // ADDED - delete expense
              InkWell(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Delete Expense', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                      content: Text('Are you sure you want to delete "$title"?', style: GoogleFonts.montserrat()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: GoogleFonts.montserrat()),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Delete', style: GoogleFonts.montserrat(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    await context.read<AppProvider>().deleteExpense(id);
                    _loadExpenses();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.delete_outline, color: Color(0xFFEF5350), size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailLabel('Payor'),
                    const SizedBox(height: 10),
                    _buildDetailLabel('Per person'),
                    const SizedBox(height: 10),
                    _buildDetailLabel('Split between'),
                    const SizedBox(height: 10),
                    _buildDetailLabel('Date'),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildDetailValue(payor),
                    const SizedBox(height: 10),
                    _buildDetailValue('₱${perPerson.toStringAsFixed(2)}'),
                    const SizedBox(height: 10),
                    _buildDetailValue(splitBetween),
                    const SizedBox(height: 10),
                    _buildDetailValue(date),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF757575)),
    );
  }

  Widget _buildDetailValue(String value) {
    return Text(
      value,
      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF2C2C2C)),
    );
  }
}
