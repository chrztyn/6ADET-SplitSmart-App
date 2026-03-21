import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class SettleDebtScreen extends StatefulWidget {
  final Map<String, dynamic> debt;

  const SettleDebtScreen({super.key, required this.debt});

  @override
  State<SettleDebtScreen> createState() => _SettleDebtScreenState();
}

class _SettleDebtScreenState extends State<SettleDebtScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();

  File? _proofImage;
  bool _isLoading = false;
  String _selectedPaymentMethod = 'GCash';
  final List<String> _paymentMethods = [
    'GCash',
    'Maya',
    'Bank Transfer',
    'Cash',
  ];

  double get _remainingBalance {
    final total = (widget.debt['amount'] as num).toDouble();
    final paid = (widget.debt['paid_amount'] as num? ?? 0).toDouble();
    return total - paid;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _proofImage = File(picked.path));
    }
  }

  Future<void> _settleDebt() async {
    final amount = double.tryParse(_amountController.text.trim());
    final maxAmount = _remainingBalance;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid amount',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount > maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount cannot exceed remaining balance of PHP ${maxAmount.toStringAsFixed(2)}',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AppProvider>().settleDebt(
        widget.debt['id'] as String,
        paymentMethod: _selectedPaymentMethod,
        amount: amount,
        proofFile: _proofImage,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Debt settled successfully!',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: const Color(0xFF43A047),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to settle debt: $e',
              style: GoogleFonts.montserrat(),
            ),
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
                          'PHP ${(widget.debt['amount'] as num).toStringAsFixed(2)}',
                          const Color(0xFFE53935),
                        ),
                        const SizedBox(height: 4),
                        _buildDetailRow(
                          'Already Paid: ',
                          'PHP ${((widget.debt['paid_amount'] as num?) ?? 0).toStringAsFixed(2)}',
                          const Color(0xFF43A047),
                        ),
                        const SizedBox(height: 4),
                        _buildDetailRow(
                          'Remaining: ',
                          'PHP ${_remainingBalance.toStringAsFixed(2)}',
                          const Color(0xFF0663FF),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildLabel('Amount to Pay*'),
                  const SizedBox(height: 8),
                  // Amount field — cap at total balance
                  _buildTextField(
                    _amountController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 22),

                  _buildLabel('Payment Method*'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFD0D0D0),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPaymentMethod,
                        isExpanded: true,
                        dropdownColor: const Color(0xFFE8F4FF),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF9E9E9E),
                        ),
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFF2C2C2C),
                        ),
                        items: _paymentMethods.map((method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(
                              method,
                              style: GoogleFonts.montserrat(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(
                            () => _selectedPaymentMethod = val ?? 'GCash',
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  _buildLabel('Proof of Payment (Optional)'),
                  const SizedBox(height: 4),
                  Text(
                    'Insert Image',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Proof of payment — image picker tap target
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
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
                      child: _proofImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _proofImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.upload_file,
                                  color: Color(0xFF9E9E9E),
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to upload proof',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: const Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

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
                        // Submit — calls _settleDebt(), disabled while loading
                        onTap: _isLoading ? null : _settleDebt,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
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
          colors: [Color(0xFF0663FF), Color(0xFF003CC1)],
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
