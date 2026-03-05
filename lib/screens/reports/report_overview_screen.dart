import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class ReportOverviewScreen extends StatefulWidget {
  const ReportOverviewScreen({super.key});

  @override
  State<ReportOverviewScreen> createState() => _ReportOverviewScreenState();
}

class _ReportOverviewScreenState extends State<ReportOverviewScreen> {

  final List<Map<String, dynamic>> youOwe = [
    {
      'expense': 'Expense Name',
      'person': 'Firstname Lastname',
      'amount': 0.00,
      'status': 'all paid'
    },
    {
      'expense': 'Expense Name',
      'person': 'Firstname Lastname',
      'amount': 0.00,
      'status': 'to pay'
    },
  ];

  final List<Map<String, dynamic>> owesYou = [
    {
      'expense': 'Expense Name',
      'person': 'Firstname Lastname',
      'amount': 0.00,
      'status': 'all paid'
    },
    {
      'expense': 'Expense Name',
      'person': 'Firstname Lastname',
      'amount': 0.00,
      'status': 'pending'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;

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
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
              child: _buildHeader(profile),
            ),

            Expanded(
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
        Row(
          children: [
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
                      ? (profile!['full_name'] as String)
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
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
            ...data.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildExpenseRow(item),
                )),
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
              item['amount'].toStringAsFixed(2),
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