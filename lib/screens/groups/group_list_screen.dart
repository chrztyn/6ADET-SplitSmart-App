import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'group_expense_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  // Dummy data for groups
  final List<Map<String, dynamic>> groups = [
    {
      'groupName': 'Group Name',
      'activityName': 'Activity Name',
      'memberCount': 'no. of members',
    },
    {
      'groupName': 'ADET Group Activity',
      'activityName': 'Midterm Web App',
      'memberCount': '25 participants',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Header Section with Gradient
          _buildHeader(context),
          
          // Body Content
          Expanded(
            child: _buildBody(context),
          ),
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
          colors: [
            Color(0xFF0663FF),
            Color(0xFF003CC1),
          ],
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
                  // Title
                  Text(
                    ' Group List',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Close button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
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

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal:40, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "My Groups" title
              Text(
                'My Groups',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 20),
              
              // Add New Group Button
              _buildAddNewGroupButton(context),
              const SizedBox(height: 24),
              
              // Group Cards
              ...groups.map((group) => _buildGroupCard(
                context: context,
                group: group,
              )),
            ],
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
          colors: [
            Color(0xFF0663FF),
            Color(0xFF003CC1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0663FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to create group screen
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
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Add New Group',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
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

  Widget _buildGroupCard({
    required BuildContext context,
    required Map<String, dynamic> group,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to group expense screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupExpenseScreen(group: group),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Row(
              children: [
                // Left side - Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Name
                      Text(
                        group['groupName'] ?? 'Group Name',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Activity Name
                      Text(
                        group['activityName'] ?? 'Activity Name',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Member Count
                      Text(
                        group['memberCount'] ?? 'no. of members',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right side - Leave Group Icon
                InkWell(
                  onTap: () {
                    // TODO: Handle leave group
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.exit_to_app,
                      color: Color(0xFFEF5350),
                      size: 26,
                    ),
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
