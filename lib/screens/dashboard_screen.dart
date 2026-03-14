import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_provider.dart';
import 'profile_screen.dart';
import 'groups/group_list_screen.dart';
import 'reports/report_overview_screen.dart';
import 'reports/transaction_history_screen.dart';
import 'groups/create_group_screen.dart';
import 'debts/debt_list_screen.dart';
import 'groups/group_expense_screen.dart';
import 'groups/add_expense_screen.dart';
import '../widgets/notification_bell.dart';

class _SubtractedCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final roundedRectPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(32),
        ),
      );

    final subtractSquareSize = 180.0;
    final subtractRadius = 45.0;

    final subtractSquarePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width - subtractSquareSize / 2,
            size.height - subtractSquareSize / 2,
            subtractSquareSize,
            subtractSquareSize,
          ),
          Radius.circular(subtractRadius),
        ),
      );

    // Path difference: inward curve cut-out at bottom-right corner
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
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedScreen(),
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
          if (index == 1) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const GroupListScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
              ),
            );
            return;
          }

          setState(() {
            _selectedIndex = index;
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _HomeTab(onProfileTap: () => setState(() => _selectedIndex = 4));
      case 1:
        return const _PlaceholderScreen(title: 'Groups');
      case 2:
        return ReportOverviewScreen(key: ValueKey(_selectedIndex));
      case 3:
        return TransactionHistoryScreen(key: ValueKey(_selectedIndex));
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
          colors: [Color(0xFFF6FAFC), Color(0xFFDCF2FF), Color(0xFFB4E4FF)],
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
  final VoidCallback? onProfileTap;

  const _HomeTab({this.onProfileTap});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  int _currentPage = 0;
  List<Map<String, dynamic>> _groups = [];
  Map<String, double> _groupTotals = {};
  bool _loadingGroups = true;
  double _iOwe = 0.0;
  double _owedToMe = 0.0;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _loadingActivities = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _loadBalance();
    _loadRecentActivities();
  }

  Future<void> _loadGroups() async {
    try {
      final provider = context.read<AppProvider>();
      await provider.refreshGroups();
      final groups = provider.myGroups;

      // Fetch full group data (with members + avatar_url) and expense totals
      final fullGroups = <Map<String, dynamic>>[];
      final totals = <String, double>{};
      for (final g in groups) {
        final groupId = g['id'] as String;
        final full = await provider.getGroup(groupId);
        fullGroups.add(full);
        totals[groupId] = await provider
            .getGroupExpenses(groupId)
            .then(
              (list) => list.fold<double>(
                0.0,
                (sum, e) => sum + (e['amount'] as num).toDouble(),
              ),
            );
      }
      if (mounted) {
        setState(() {
          _groups = fullGroups;
          _groupTotals = totals;
          _loadingGroups = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingGroups = false);
    }
  }

  Future<void> _loadBalance() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final provider = context.read<AppProvider>();
      final debts = await provider.getMyDebts();

      double owe = 0.0;
      double owed = 0.0;
      for (final d in debts) {
        final total = (d['amount'] as num?)?.toDouble() ?? 0.0;
        final paid = (d['paid_amount'] as num?)?.toDouble() ?? 0.0;
        final remaining = total - paid;
        final status = d['status'] as String? ?? '';
        if (status == 'pending') {
          if (d['from_user_id'] == currentUserId) owe += remaining;
          if (d['to_user_id'] == currentUserId) owed += remaining;
        }
      }

      if (mounted) {
        setState(() {
          _iOwe = owe;
          _owedToMe = owed;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load balance: $e',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final provider = context.read<AppProvider>();
      final debts = await provider.getMyDebts();

      final debtEntries = debts.map((d) {
        final bool isFrom = (d['from_user_id'] as String?) == currentUserId;
        final String otherName = isFrom
            ? ((d['to_user'] as Map?)?['name'] as String?) ?? 'Unknown'
            : ((d['from_user'] as Map?)?['name'] as String?) ?? 'Unknown';
        final amount = (d['amount'] as num?)?.toDouble() ?? 0.0;
        final status = d['status'] as String? ?? 'pending';
        final type = status == 'settled' ? 'Settlement' : 'Debt';
        return {
          'type': type,
          'description': (d['expense'] as Map?)?['description'] ?? 'Expense',
          'group': (d['group'] as Map?)?['name'] ?? 'Unknown Group',
          'fromTo': otherName,
          'amount': isFrom
              ? '-PHP ${amount.toStringAsFixed(2)}'
              : '+PHP ${amount.toStringAsFixed(2)}',
          'status': status,
          'isFrom': isFrom,
          'sortDate': (d['created_at'] as String?) ?? '',
          'date': (d['created_at'] as String?)?.split('T').first ?? '',
        };
      }).toList();

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
          'type': 'Partial Payment',
          'description':
              ((debt?['expense'] as Map?)?['description'] as String?) ??
              'Expense',
          'group':
              ((debt?['group'] as Map?)?['name'] as String?) ?? 'Unknown Group',
          'fromTo': otherName,
          'amount': '-PHP ${paidAmount.toStringAsFixed(2)}',
          'status': 'paid',
          'isFrom': true,
          'sortDate': (p['created_at'] as String?) ?? '',
          'date': (p['created_at'] as String?)?.split('T').first ?? '',
        };
      }).toList();

      final all = [...debtEntries, ...paymentEntries];
      all.sort(
        (a, b) => (b['sortDate'] as String).compareTo(a['sortDate'] as String),
      );

      if (mounted) {
        setState(() {
          _recentActivities = all.take(5).toList();
          _loadingActivities = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingActivities = false);
    }
  }

  void _navigateToNextCard() {
    final maxPage = _groups.isEmpty ? 0 : _groups.length - 1;
    if (_currentPage < maxPage) {
      setState(() => _currentPage++);
    } else if (_groups.isEmpty || _currentPage == maxPage) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
      ).then((_) => _loadGroups());
    }
  }

  void _navigateToPreviousCard() {
    if (_currentPage > 0) setState(() => _currentPage--);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

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
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _loadGroups(),
                _loadBalance(),
                _loadRecentActivities(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, provider),
                    const SizedBox(height: 24),

                    // Main Expense Card with horizontal slide animation
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity != null) {
                              if (details.primaryVelocity! < 0 &&
                                  _currentPage == 0) {
                                _navigateToNextCard();
                              } else if (details.primaryVelocity! > 0 &&
                                  _currentPage == 1) {
                                _navigateToPreviousCard();
                              }
                            }
                          },
                          child: ClipRect(
                            child: _loadingGroups
                                ? const SizedBox(
                                    height: 220,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : _groups.isEmpty
                                ? _buildEmptyGroupCard(context)
                                : Stack(
                                    children: List.generate(_groups.length, (
                                      index,
                                    ) {
                                      return AnimatedSlide(
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeInOut,
                                        offset: Offset(
                                          (index - _currentPage).toDouble(),
                                          0,
                                        ),
                                        child: _buildGroupCard(
                                          context,
                                          _groups[index],
                                          index,
                                        ),
                                      );
                                    }),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 42),

                    // Quick Access + Balance Overview
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildQuickAccessCard(context)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildBalanceOverviewCard(context)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 38),

                    _buildRecentActivities(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    final profile = provider.profile;

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
              onTap: () => widget.onProfileTap?.call(),
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
                                ? ((profile!['name'] as String).isNotEmpty
                                      ? (profile['name'] as String)
                                            .substring(0, 1)
                                            .toUpperCase()
                                      : '?')
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

  Widget _buildGroupCard(
    BuildContext context,
    Map<String, dynamic> group,
    int index,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        const buttonSize = 56.0;

        final buttonRight = (cardWidth * 0.01) + 4;
        const buttonBottom = 8.0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupExpenseScreen(group: group),
              ),
            ).then((_) => _loadGroups());
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main card with custom clipped shape
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
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                      'PHP ${(_groupTotals[group['id']] ?? 0.0).toStringAsFixed(2)}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF003CC1),
                                      ),
                                    ),
                                  ],
                                ),

                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
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
                                        Expanded(
                                          child: Text(
                                            group['name'] ?? 'Group',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            softWrap: false,
                                            style: GoogleFonts.montserrat(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF424242),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Text(
                              'Split with',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF424242),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildGroupMemberAvatars(group),
                            const SizedBox(height: 24),

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
                                borderRadius: BorderRadius.circular(
                                  22,
                                ), // Fully rounded edges
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF003CC1,
                                    ).withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddExpenseScreen(
                                          groupId: group['id'] as String,
                                          groupName: group['name'] as String,
                                        ),
                                      ),
                                    ).then((_) => _loadGroups());
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
                      colors: [Color(0xFF0254D8), Color(0xFF003CC1)],
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
                          turns: _currentPage > 0 ? 0.5 : 0.0,
                          child: Icon(
                            (_groups.length == 1)
                                ? Icons.add
                                : Icons.arrow_forward,
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
          ),
        );
      },
    );
  }

  Widget _buildGroupMemberAvatars(Map<String, dynamic> group) {
    final members = (group['members'] as List?) ?? [];
    final memberCount = (group['member_count'] as int?) ?? members.length;

    final avatarColors = [
      const Color(0xFFFDD835),
      const Color(0xFFFF7043),
      const Color(0xFFBA68C8),
      const Color(0xFF42A5F5),
      const Color(0xFF66BB6A),
      const Color(0xFFEF5350),
    ];

    final displayCount = memberCount.clamp(0, 4);
    final overflow = memberCount > 4 ? memberCount - 4 : 0;

    return SizedBox(
      height: 32,
      child: Stack(
        children: [
          ...List.generate(displayCount, (index) {
            final member = members.length > index
                ? members[index]['user'] as Map?
                : null;
            final initial = member?['name'] != null
                ? ((member!['name'] as String).isNotEmpty
                      ? (member['name'] as String).substring(0, 1).toUpperCase()
                      : '')
                : '';
            return Positioned(
              left: index * 22.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: avatarColors[index % avatarColors.length],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: member?['avatar_url'] != null
                      ? Image.network(
                          member!['avatar_url'] as String,
                          fit: BoxFit.cover,
                          width: 32,
                          height: 32,
                          errorBuilder: (_, __, ___) => initial.isNotEmpty
                              ? Center(
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                        )
                      : initial.isNotEmpty
                      ? Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
            );
          }),
          if (overflow > 0)
            Positioned(
              left: displayCount * 22.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF003CC1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$overflow',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyGroupCard(BuildContext context) {
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
                      Color.fromARGB(255, 165, 202, 251),
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
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
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
                                      'No Groups Yet',
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

                          Text(
                            'Split with',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF424242),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(height: 32),
                          const SizedBox(height: 24),

                          Container(
                            width: 120,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF003CC1), Color(0xFF0254D8)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF003CC1,
                                  ).withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CreateGroupScreen(),
                                  ),
                                ).then((_) => _loadGroups()),
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
                    colors: [Color(0xFF0254D8), Color(0xFF003CC1)],
                    center: Alignment.center,
                    radius: 0.8,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateGroupScreen(),
                      ),
                    ).then((_) => _loadGroups()),
                    borderRadius: BorderRadius.circular(28),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.white, size: 24),
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
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            context,
            icon: Icons.check_circle_outline,
            label: 'Settle Debt',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DebtListScreen()),
              );
              if (mounted) await _loadBalance();
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
          colors: [Color(0xFF003CC1), Color(0xFF038AFF)],
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
    final iOwe = _iOwe;
    final owedToMe = _owedToMe;
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
            amount: iOwe.toStringAsFixed(2),
            color: const Color(0xFFEF5350),
            backgroundColor: const Color(0xFFFFEBEE),
            borderColor: const Color(0xFFEF5350).withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          _buildBalanceItem(
            label: 'Owed',
            amount: owedToMe.toStringAsFixed(2),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                label == 'Owe' ? '−' : '+',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              amount,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    Color _dotColor(String type, String status) {
      if (type == 'Settlement') return const Color(0xFF27A862);
      if (type == 'Partial Payment') return const Color(0xFF1A73E8);
      if (status == 'pending') return const Color(0xFFF57C00);
      return const Color(0xFF038AFF);
    }

    Color _amountColor(bool isFrom) =>
        isFrom ? const Color(0xFFE53935) : const Color(0xFF27A862);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionHistoryScreen(),
                ),
              ),
              child: Text(
                'See All',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF038AFF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_loadingActivities)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_recentActivities.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No recent activity',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF9E9E9E),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ..._recentActivities.map((a) {
            final type = a['type'] as String;
            final status = a['status'] as String;
            final isFrom = a['isFrom'] as bool;
            final dot = _dotColor(type, status);
            final amtColor = _amountColor(isFrom);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
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
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${a['description']}',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF003CC1),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${a['type']} · ${a['group']}',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
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
                          a['amount'] as String,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: amtColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a['date'] as String,
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
          }),
      ],
    );
  }
}

// ignore_for_file: unused_element
class _NotifDropdown extends StatelessWidget {
  final LayerLink link;
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final VoidCallback onClose;
  final VoidCallback onMarkAllRead;
  final VoidCallback onViewAll;

  const _NotifDropdown({
    required this.link,
    required this.notifications,
    required this.unreadCount,
    required this.onClose,
    required this.onMarkAllRead,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Notification dropdown — anchored below bell icon
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(20),
            shadowColor: const Color(0xFF038AFF).withOpacity(0.15),
            child: Container(
              width: 320,
              constraints: const BoxConstraints(maxHeight: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCF2FF), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                    child: Row(
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF003CC1),
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B3B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount new',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (unreadCount > 0)
                          TextButton(
                            onPressed: onMarkAllRead,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Mark all read',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: const Color(0xFF038AFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFEEF5FF)),

                  if (notifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none_outlined,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No notifications yet',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFEEF5FF),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (_, i) =>
                            _NotifTile(notification: notifications[i]),
                      ),
                    ),

                  if (notifications.isNotEmpty) ...[
                    const Divider(height: 1, color: Color(0xFFEEF5FF)),
                    InkWell(
                      onTap: onViewAll,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'View all notifications',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF038AFF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _NotifTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] as String? ?? '';
    final message = notification['message'] as String? ?? '';
    final isRead = notification['is_read'] as bool? ?? true;
    final createdAt = notification['created_at'] as String? ?? '';

    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (type) {
      case 'new_expense':
        icon = Icons.receipt_long_outlined;
        iconBg = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF038AFF);
        break;
      case 'debt_settled':
        icon = Icons.check_circle_outline;
        iconBg = const Color(0xFFE8F5E9);
        iconColor = const Color(0xFF2E7D32);
        break;
      default:
        icon = Icons.notifications_outlined;
        iconBg = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF038AFF);
    }

    return Container(
      color: isRead ? Colors.transparent : const Color(0xFFF0F8FF),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(createdAt),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),

            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF038AFF),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(String createdAt) {
    if (createdAt.isEmpty) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
