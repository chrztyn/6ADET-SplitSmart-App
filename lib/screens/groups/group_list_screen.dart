import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'group_expense_screen.dart';
import 'create_group_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refreshGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final groups = provider.myGroups;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody(context, groups, provider)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0663FF), Color(0xFF003CC1)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ' Group List',
                    style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Map<String, dynamic>> groups, AppProvider provider) {
    return Container(
      color: Colors.white,
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.refreshGroups(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Groups',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildAddNewGroupButton(context),
                      const SizedBox(height: 24),

                      if (groups.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Text(
                              'No groups yet.\nTap "Add New Group" to get started!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(fontSize: 14, color: const Color(0xFF9E9E9E)),
                            ),
                          ),
                        )
                      else
                        ...groups.map((group) => _buildGroupCard(context: context, group: group, provider: provider)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAddNewGroupButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0663FF), Color(0xFF003CC1)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0663FF).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
            );
            if (result == true && mounted) {
              context.read<AppProvider>().refreshGroups();
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 12),
              Text(
                'Add New Group',
                style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard({
    required BuildContext context,
    required Map<String, dynamic> group,
    required AppProvider provider,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => GroupExpenseScreen(group: group)));
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FIXED - real group name
                      Text(
                        group['name'] ?? 'Group Name',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // FIXED - real description
                      Text(
                        group['description'] ?? '',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // FIXED - real member count
                      Text(
                        '${group['member_count'] ?? 1} member(s)',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),

                // Leave group with confirmation dialog
                InkWell(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Leave Group', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                        content: Text(
                          'Are you sure you want to leave "${group['name']}"?',
                          style: GoogleFonts.montserrat(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Cancel', style: GoogleFonts.montserrat()),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('Leave', style: GoogleFonts.montserrat(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      await provider.deleteGroup(group['id']);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.exit_to_app, color: Color(0xFFEF5350), size: 26),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
