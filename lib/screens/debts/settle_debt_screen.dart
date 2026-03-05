import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettleDebtScreen extends StatefulWidget {
  final Map<String, dynamic> debt;

  const SettleDebtScreen({super.key, required this.debt});

  @override
  State<SettleDebtScreen> createState() => _SettleDebtScreenState();
}

class _SettleDebtScreenState extends State<SettleDebtScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentMethodController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Details card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Details',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C2C2C),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          'Group: ',
                          widget.debt['groupName'],
                          const Color(0xFF0663FF),
                        ),
                        const SizedBox(height: 4),
                        _buildDetailRow(
                          'You Owe: ',
                          widget.debt['oweTo'],
                          const Color(0xFF0663FF),
                        ),
                        const SizedBox(height: 4),
                        _buildDetailRow(
                          'Total Debt: ',
                          widget.debt['amount'].toStringAsFixed(2),
                          const Color(0xFFE53935),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Amount to Pay
                  _buildLabel('Amount to Pay*'),
                  const SizedBox(height: 8),
                  // TODO: validate amount does not exceed total debt
                  _buildTextField(_amountController,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 22),

                  // Payment Method
                  _buildLabel('Payment Method*'),
                  const SizedBox(height: 8),
                  // TODO: replace with dropdown of payment methods
                  _buildTextField(_paymentMethodController),
                  const SizedBox(height: 22),

                  // Proof of Payment
                  _buildLabel('Proof of Payment*'),
                  const SizedBox(height: 4),
                  Text(
                    'Insert Image',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // TODO: implement image_picker for proof of payment
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFD0D0D0),
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Settle Debt button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF43A047).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        // TODO: implement settle debt backend logic
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Text(
                            'Settle Debt',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
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
            ),
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
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settle Debt',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
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

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2C2C2C),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        color: const Color(0xFF2C2C2C),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD0D0D0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0663FF), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.montserrat(
          fontSize: 13,
          color: const Color(0xFF2C2C2C),
        ),
        children: [
          TextSpan(text: label),
          TextSpan(
            text: value,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}