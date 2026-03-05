import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'profile_screen.dart';
import 'groups/group_list_screen.dart';
import 'reports/report_overview_screen.dart';
import 'reports/transaction_history_screen.dart';
import 'groups/create_group_screen.dart';
import 'debts/debt_list_screen.dart';

// Custom clipper for boolean subtract operation (Figma-style)
// Creates a rounded card with a rounded square cut out from bottom-right corner
class _SubtractedCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Create base rounded rectangle path
    final roundedRectPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(32),
        ),
      );

    // Create rounded square for subtraction (positioned at bottom-right)
    // Positioned to overlap the bottom-right corner of the main card
    final subtractSquareSize = 180.0;
    final subtractRadius = 45.0;
    
    final subtractSquarePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width - subtractSquareSize / 2, // Start halfway outside the card
            size.height - subtractSquareSize / 2, // Start halfway outside the card
            subtractSquareSize,
            subtractSquareSize,
          ),
          Radius.circular(subtractRadius),
        ),
      );

    // Boolean subtract operation: subtract rounded square from rounded rectangle
    // This creates the inward curved cut-out on the bottom-right
    final subtractedPath = Path.combine(
      PathOperation.difference,
      roundedRectPath,
      subtractSquarePath,
    );

    return subtractedPath;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedScreen(),
      bottomNavigationBar: _CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          // Handle Groups (index 1) as modal
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const GroupListScreen(),
                fullscreenDialog: true,
              ),
            );
          } else {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const _HomeTab();
      case 1:
        // TODO: Replace with Groups screen
        return const _PlaceholderScreen(title: 'Groups');
      case 2:
        return const ReportOverviewScreen();
      case 3:
        return const TransactionHistoryScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const _HomeTab();
    }
  }
}

// Placeholder screen for unimplemented sections
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 64,
                color: const Color(0xFF038AFF),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003CC1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coming Soon',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  int _currentPage = 0;

  void _navigateToNextCard() {
    if (_currentPage < 1) {
      setState(() {
        _currentPage = 1;
      });
    }
  }

  void _navigateToPreviousCard() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;

    return Scaffold(
      body: Container(
        // Soft blue gradient background
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Section
                  _buildHeader(context, profile),
                  const SizedBox(height: 24),

                  // Main Expense Card with horizontal slide animation
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity != null) {
                            if (details.primaryVelocity! < 0 && _currentPage == 0) {
                              _navigateToNextCard();
                            } else if (details.primaryVelocity! > 0 && _currentPage == 1) {
                              _navigateToPreviousCard();
                            }
                          }
                        },
                        child: ClipRect(
                          child: Stack(
                            children: [
                              AnimatedSlide(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                offset: Offset(_currentPage == 0 ? 0.0 : -1.0, 0),
                                child: _buildMainExpenseCard(context, isFirstCard: true),
                              ),
                              AnimatedSlide(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                offset: Offset(_currentPage == 0 ? 1.0 : 0.0, 0),
                                child: _buildSecondCard(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 42),

                  // Quick Access + Balance Overview
                  Row(
                    children: [
                      Expanded(child: _buildQuickAccessCard(context)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBalanceOverviewCard(context)),
                    ],
                  ),
                  const SizedBox(height: 38),

                  // Recent Activities Section
                  _buildRecentActivities(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
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
                    Color(0xFF0254D8), // Lighter blue at center
                    Color(0xFF003CC1), // Darker blue at edges
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

  Widget _buildMainExpenseCard(BuildContext context, {bool isFirstCard = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive button positioning based on card width
        final cardWidth = constraints.maxWidth;
        const buttonSize = 56.0;
        
        // Using percentage-based offsets for responsiveness
        final buttonRight = (cardWidth * 0.01) + 4; // ~1% of width + 4px offset (closer to right)
        const buttonBottom = 8.0; // 8px up from center
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Main card with custom clipped shape (boolean subtract)
            ClipPath(
              clipper: _SubtractedCardClipper(),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.65, 1.0],
                    colors: [
                      Color(0xFFE3F2FD), 
                      Color(0xFFC4D9F5),
                      Color.fromARGB(255, 165, 202, 251),
                    ],
                  ),
                  // Subtle border for depth
                  border: Border.all(
                    color: const Color(0xFF9AB8E8).withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF038AFF).withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFF003CC1).withOpacity(0.3),
                      blurRadius: 50,
                      offset: const Offset(0, 18),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Blur effect at top of card background only
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Card content
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Top row: Total Expenses and Group indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Total Expenses
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expenses',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PHP 0.00',
                        style: GoogleFonts.montserrat(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003CC1),
                        ),
                      ),
                    ],
                  ),

                  // Right: Group indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF038AFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ADET Group',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Middle: Split with avatars
              Text(
                'Split with',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 12),
              _buildOverlappingAvatars(),
              const SizedBox(height: 24),

              // Bottom: Split Now button - Custom rounded pill button
              Container(
                width: 120,
                height: 44,
                decoration: BoxDecoration(
                  // Strong blue gradient
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF003CC1),
                      Color(0xFF0254D8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22), // Fully rounded edges
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF003CC1).withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // TODO: Navigate to split expense
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Center(
                      child: Text(
                        'Split Now',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
                      ),
                    ), 
                  ],
                ), 
        ),
            ), 

            // Floating arrow button (centered in the hidden square - responsive)
            Positioned(
              right: buttonRight,
              bottom: buttonBottom,
              child: Container(
                width: buttonSize,
                height: buttonSize,
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
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_currentPage == 0) {
                        _navigateToNextCard();
                      } else {
                        _navigateToPreviousCard();
                      }
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Center(
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: _currentPage == 0 ? 0 : 0.5,
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverlappingAvatars() {
    final avatarColors = [
      const Color(0xFFFDD835),
      const Color(0xFFFF7043), 
      const Color(0xFFBA68C8),
      const Color(0xFF42A5F5),
    ];

    return SizedBox(
      height: 32,
      child: Stack(
        children: [
          ...List.generate(4, (index) {
            return Positioned(
              left: index * 22.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: avatarColors[index],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            );
          }),
          // Add button
          Positioned(
            left: 4 * 22.0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF003CC1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        const buttonSize = 56.0;
        final buttonRight = (cardWidth * 0.01) + 4;
        const buttonBottom = 8.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipPath(
              clipper: _SubtractedCardClipper(),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.65, 1.0],
                    colors: [
                      Color(0xFFE3F2FD),
                      Color(0xFFC4D9F5), 
                      Color.fromARGB(255, 138, 181, 251)
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF9AB8E8).withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF038AFF).withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFF003CC1).withOpacity(0.3),
                      blurRadius: 50,
                      offset: const Offset(0, 18),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Card content
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Total Expenses and Group indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Total Expenses
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Expenses',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF424242),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PHP 0.00',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF003CC1),
                                    ),
                                  ),
                                ],
                              ),

                              // Right: Group indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF038AFF),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Family Group',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF424242),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Middle: Split with avatars
                          Text(
                            'Split with',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF424242),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildOverlappingAvatars(),
                          const SizedBox(height: 24),

                          // Bottom: Split Now button - Custom rounded pill button
                          Container(
                            width: 120,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF003CC1),
                                  Color(0xFF0254D8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22), 
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF003CC1).withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // TODO: Navigate to split expense
                                },
                                borderRadius: BorderRadius.circular(22),
                                child: Center(
                                  child: Text(
                                    'Split Now',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: buttonRight,
              bottom: buttonBottom,
              child: Container(
                width: buttonSize,
                height: buttonSize,
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
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_currentPage == 0) {
                        _navigateToNextCard();
                      } else {
                        _navigateToPreviousCard();
                      }
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Center(
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: _currentPage == 0 ? 0 : 0.5,
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAccessCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE3F2FD),
            Color(0xFFC4D9F5),
            Color.fromARGB(255, 165, 202, 251),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Quick Access',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003CC1),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActionButton(
            context,
            icon: Icons.add_circle_outline,
            label: 'New Group',
            onTap: () {
              // TODO: Navigate to create group
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            context,
            icon: Icons.check_circle_outline,
            label: 'Settle Debt',
            onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DebtListScreen(),
    ),
  );
},
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF003CC1),
            Color(0xFF038AFF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003CC1).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
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

  Widget _buildBalanceOverviewCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE3F2FD),
            Color(0xFFC4D9F5),
            Color.fromARGB(255, 165, 202, 251),

          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color.fromARGB(255, 158, 158, 158).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Balance Overview',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003CC1),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildBalanceItem(
            label: 'Owe',
            amount: '0.00',
            color: const Color(0xFFEF5350),
            backgroundColor: const Color(0xFFFFEBEE),
            borderColor: const Color(0xFFEF5350).withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          _buildBalanceItem(
            label: 'Owed',
            amount: '0.00',
            color: const Color(0xFF66BB6A),
            backgroundColor: const Color(0xFFE8F5E9),
            borderColor: const Color(0xFF66BB6A).withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem({
    required String label,
    required String amount,
    required Color color,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF424242),
              ),
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    final activities = [
      {
        'title': 'Marked settlement',
        'time': '2 hours ago',
        'color': const Color(0xFF66BB6A),
      },
      {
        'title': 'Added expense',
        'time': '5 hours ago',
        'color': const Color(0xFFEF5350),
      },
      {
        'title': 'Created a group',
        'time': 'yesterday',
        'color': const Color(0xFFBA68C8),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activities',
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003CC1),
              ),
            ),
            Text(
              'See All',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF038AFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Activity items
        ...activities.map((activity) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Colored status dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: activity['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Activity text
                  Expanded(
                    child: Text(
                      activity['title'] as String,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF003CC1),
                      ),
                    ),
                  ),

                  // Timestamp
                  Text(
                    activity['time'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// Custom Bottom Navigation Bar
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
      decoration: BoxDecoration(
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
