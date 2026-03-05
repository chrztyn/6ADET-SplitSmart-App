import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

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

  final List<Map<String, dynamic>> transactions = [
    {
      'type': 'Settlement',
      'description': 'Lunch Food',
      'group': 'Group Name',
      'fromTo': 'Micah Lapuz',
      'amount': '+0.00',
      'status': 'confirmed',
      'date': 'mm/dd/yyyy',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _typeController.dispose();
    _statusController.dispose();
    _groupController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
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
            // Header — matches dashboard exactly
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
                    'Transaction History',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003CC1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View and manage all your financial transactions',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF7A7A7A),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSummaryGrid(),
                  const SizedBox(height: 24),

                  _buildFilterCard(),
                  const SizedBox(height: 24),

                  ...transactions.map((t) => _buildTransactionCard(t)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header (identical to dashboard) ───────────────────────────────────────

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
            // Notification bell — exact same as dashboard
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

            // Profile avatar — exact same as dashboard
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

  // ─── Summary 2×2 grid (Card widget) ────────────────────────────────────────

  Widget _buildSummaryGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                label: 'Total Spent',
                value: 'PHP 0.00',
                valueColor: const Color(0xFFE53935),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                label: 'Total Received',
                value: 'PHP 0.00',
                valueColor: const Color(0xFF27A862),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                label: 'Total Paid',
                value: 'PHP 0.00',
                valueColor: const Color(0xFFF57C00),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                label: 'Net Balance',
                value: 'PHP 0.00',
                valueColor: const Color(0xFF7B1FA2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5A5A5A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filter card (Card widget) ─────────────────────────────────────────────

  Widget _buildFilterCard() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterLabel('Search'),
            const SizedBox(height: 6),
            _buildTextField(_searchController),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterLabel('Type'),
                      const SizedBox(height: 6),
                      _buildTextField(_typeController),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterLabel('Status'),
                      const SizedBox(height: 6),
                      _buildTextField(_statusController),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterLabel('Group'),
                      const SizedBox(height: 6),
                      _buildTextField(_groupController),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterLabel('Start Date'),
                      const SizedBox(height: 6),
                      _buildTextField(_startDateController),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterLabel('End Date'),
                      const SizedBox(height: 6),
                      _buildTextField(_endDateController),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                // Apply Filters button
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF038AFF), Color(0xFF003CC1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Center(
                          child: Text(
                            'Apply Filters',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Clear All button
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFD0D0D0),
                      width: 1.2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _searchController.clear();
                        _typeController.clear();
                        _statusController.clear();
                        _groupController.clear();
                        _startDateController.clear();
                        _endDateController.clear();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Center(
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5A5A5A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF5A5A5A),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        style: GoogleFonts.montserrat(fontSize: 12),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD8D8D8), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFF038AFF), width: 1.2),
          ),
        ),
      ),
    );
  }

  // ─── Transaction card (Card widget) ────────────────────────────────────────

  Widget _buildTransactionCard(Map<String, dynamic> t) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          children: [
            _buildTransactionRow('Type', t['type']),
            const SizedBox(height: 10),
            _buildTransactionRow('Description', t['description']),
            const SizedBox(height: 10),
            _buildTransactionRow('Group', t['group']),
            const SizedBox(height: 10),
            _buildTransactionRow('From/To', t['fromTo']),
            const SizedBox(height: 10),
            _buildTransactionRow('Amount', t['amount']),
            const SizedBox(height: 10),
            _buildStatusRow('Status', t['status']),
            const SizedBox(height: 10),
            _buildTransactionRow('Date', t['date']),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A3A),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF5A5A5A),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A3A),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD4F2E3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF27A862),
            ),
          ),
        ),
      ],
    );
  }
}