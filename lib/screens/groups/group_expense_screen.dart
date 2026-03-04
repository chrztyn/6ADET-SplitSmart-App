import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../dashboard_screen.dart';
import 'group_list_screen.dart';

class GroupExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupExpenseScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupExpenseScreen> createState() => _GroupExpenseScreenState();
}

class _GroupExpenseScreenState extends State<GroupExpenseScreen> {
  int _selectedIndex = 1; // Groups tab is active

  // Dummy expense data
  final List<Map<String, dynamic>> expenses = [
    {
      'title': 'Groceries',
      'amount': 1500.00,
      'payor': 'Micah Lapuz',
      'perPerson': 375.00,
      'splitBetween': '4 members',
      'date': '03/01/2026',
    },
    {
      'title': 'Restaurant Dinner',
      'amount': 2400.00,
      'payor': 'Maxene Quiambao',
      'perPerson': 600.00,
      'splitBetween': '4 members',
      'date': '03/03/2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;

    return Scaffold(
      body: Container(
        // Same background gradient as Dashboard
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6FAFC),
              Color(0xFFDCF2FF),
              Color(0xFFB4E4FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header (Same as Dashboard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                child: _buildHeader(context, profile),
              ),

              // Group Info Section with Buttons
              _buildGroupInfoSection(context),

              // Expense Cards List
              Expanded(
                child: _buildExpenseList(context),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) {
            // Navigate back to dashboard (home tab)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(initialIndex: 0),
              ),
              (route) => false,
            );
          } else if (index == 1) {
            // Groups - navigate back to group list
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const GroupListScreen(),
                fullscreenDialog: true,
              ),
              (route) => route.isFirst,
            );
          } else if (index == 2) {
            // Reports - go to dashboard with reports tab
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(initialIndex: 2),
              ),
              (route) => false,
            );
          } else if (index == 3) {
            // Transaction History - go to dashboard with history tab
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(initialIndex: 3),
              ),
              (route) => false,
            );
          } else if (index == 4) {
            // Profile - go to dashboard with profile tab
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(initialIndex: 4),
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic>? profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: SplitSmart with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF003CC1),
              Color(0xFF038AFF),
              Color(0xFF01A7FF),
            ],
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

        // Right: Notification bell and profile avatar
        Row(
          children: [
            // Notification bell
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 230, 245, 255).withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF038AFF),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Profile avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF0254D8),
                    Color(0xFF003CC1), 
                  ],
                  center: Alignment.center,
                  radius: 0.8,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  profile?['full_name'] != null
                      ? (profile!['full_name'] as String).substring(0, 1).toUpperCase()
                      : 'M',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
        // Divider
        Container(
          height: 1,
          color: Colors.white.withOpacity(0.5),
        ),
        
        // Group Info and Buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Name
              Text(
                widget.group['groupName'] ?? 'Group Name',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003CC1),
                ),
              ),
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  _buildActionButton(
                    context,
                    label: 'Add Member',
                    icon: Icons.person_add_outlined,
                    onTap: () {
                      // TODO: Navigate to add member screen
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    context,
                    label: 'New Expense',
                    icon: Icons.add_circle_outline,
                    onTap: () {
                      // TODO: Navigate to new expense screen
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Bottom Divider
        Container(
          height: 1,
          color: Colors.white.withOpacity(0.5),
        ),
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
        gradient: const LinearGradient(
          colors: [
            Color(0xFF003CC1),
            Color(0xFF038AFF),
          ],
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return _buildExpenseCard(
          title: expense['title'],
          amount: expense['amount'],
          payor: expense['payor'],
          perPerson: expense['perPerson'],
          splitBetween: expense['splitBetween'],
          date: expense['date'],
        );
      },
    );
  }

  Widget _buildExpenseCard({
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
        border: Border.all(
          color: const Color(0xFF038AFF).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Title/Amount and Delete Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Title and Amount
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
              
              // Right: Delete Icon
              InkWell(
                onTap: () {
                  // TODO: Handle delete expense
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF5350),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Bottom Content: Two-column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Labels
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
              
              // Right Column: Values
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
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF757575),
      ),
    );
  }

  Widget _buildDetailValue(String value) {
    return Text(
      value,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF2C2C2C),
      ),
    );
  }
}

// Custom Bottom Navigation Bar (reused from dashboard)
class _CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _CustomBottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.dashboard_outlined, 0),
          _buildNavItem(Icons.group_outlined, 1),
          _buildNavItem(Icons.article_outlined, 2),
          _buildNavItem(Icons.history_outlined, 3),
          _buildNavItem(Icons.person_outline, 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF038AFF).withOpacity(0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF003CC1) : const Color(0xFF9E9E9E),
          size: 26,
        ),
      ),
    );
  }
}
