import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/skeleton.dart';
import '../profile_screen.dart';

class ReportOverviewScreen extends StatefulWidget {
  const ReportOverviewScreen({super.key});

  @override
  State<ReportOverviewScreen> createState() => _ReportOverviewScreenState();
}

class _ReportOverviewScreenState extends State<ReportOverviewScreen> {
  List<Map<String, dynamic>> youOwe = [];
  List<Map<String, dynamic>> owesYou = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<AppProvider>();
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      await provider.refreshDebts();
      final allDebts = provider.myDebts;

      if (mounted) {
        setState(() {
          youOwe = allDebts
              .where((d) => d['from_user_id'] == currentUserId)
              .map(
                (d) => {
                  'expense':
                      (d['expense'] as Map?)?['description'] ?? 'Expense',
                  'person': (d['to_user'] as Map?)?['name'] ?? 'Unknown',
                  'amount':
                      ((d['amount'] as num?)?.toDouble() ?? 0.0) -
                      ((d['paid_amount'] as num?)?.toDouble() ?? 0.0),
                  'status': d['status'] == 'settled' ? 'all paid' : 'to pay',
                },
              )
              .toList();

          owesYou = allDebts
              .where((d) => d['to_user_id'] == currentUserId)
              .map(
                (d) => {
                  'expense':
                      (d['expense'] as Map?)?['description'] ?? 'Expense',
                  'person': (d['from_user'] as Map?)?['name'] ?? 'Unknown',
                  'amount':
                      ((d['amount'] as num?)?.toDouble() ?? 0.0) -
                      ((d['paid_amount'] as num?)?.toDouble() ?? 0.0),
                  'status': d['status'] == 'settled' ? 'all paid' : 'pending',
                },
              )
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e), style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;

    return Container(
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
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
              child: _buildHeader(profile),
            ),

            Expanded(
              child: _isLoading
                  ? ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 8,
                      ),
                      children: [
                        const SkeletonBox(
                          width: 160,
                          height: 22,
                          borderRadius: 8,
                        ),
                        const SizedBox(height: 24),
                        ...List.generate(
                          5,
                          (_) => const Padding(
                            padding: EdgeInsets.only(bottom: 14),
                            child: SkeletonCard(),
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDebts,
                      child: ListView(
                        padding: const EdgeInsets.only(
                          left: 36,
                          right: 36,
                          bottom: 32,
                        ),
                        children: [
                          Text(
                            'Report Details',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF003CC1),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildReportCard(
                            title: 'You Owe',
                            subtitle:
                                'A list of all the money you need to pay to other group members.',
                            data: youOwe,
                          ),
                          const SizedBox(height: 28),

                          _buildReportCard(
                            title: 'Owes You',
                            subtitle:
                                'A list of all the money that other group members need to pay you.',
                            data: owesYou,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

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

  // ─── Report Card (uses Flutter Card widget for milestone) ──────────────────

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> data,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF7A7A7A),
              ),
            ),
            const SizedBox(height: 18),
            if (data.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Nothing to show here',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFF9E9E9E),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...data.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildExpenseRow(item),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseRow(Map<String, dynamic> item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['expense'],
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A4A4A),
              ),
            ),
            Text(
              item['person'],
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: const Color(0xFF8B8B8B),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              (item['amount'] as num).toStringAsFixed(2),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(width: 12),
            _buildStatusChip(item['status']),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;

    if (status == 'all paid') {
      bg = const Color(0xFFD9F4E4);
      text = const Color(0xFF2E9F64);
    } else if (status == 'to pay') {
      bg = const Color(0xFFF9D9D9);
      text = const Color(0xFFD64545);
    } else {
      bg = const Color(0xFFE6E6E6);
      text = const Color(0xFF6B6B6B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
