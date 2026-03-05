import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  String _selectedPayer = 'Micah Lapuz';
  String _selectedSplit = 'All Members (2)';

  // TODO: fetch actual group members from Supabase for dropdowns
  final List<String> _payers = ['Micah Lapuz', 'Maxene Quiambao'];
  final List<String> _splitOptions = ['All Members (2)', 'Select Members'];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _statusController.dispose();
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
                  _buildLabel('Description*'),
                  const SizedBox(height: 8),
                  _buildTextField(_descriptionController),
                  const SizedBox(height: 20),

                  _buildLabel('Amount*'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    _amountController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Who Paid*'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _selectedPayer,
                    items: _payers,
                    onChanged: (val) => setState(() => _selectedPayer = val!),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Split Between*'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _selectedSplit,
                    items: _splitOptions,
                    onChanged: (val) => setState(() => _selectedSplit = val!),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Date'),
                  const SizedBox(height: 8),
                  _buildTextField(_dateController),
                  const SizedBox(height: 20),

                  _buildLabel('Status'),
                  const SizedBox(height: 8),
                  _buildTextField(_statusController),
                  const SizedBox(height: 20),

                  _buildLabel('Upload Image Receipt'),
                  const SizedBox(height: 8),
                  // TODO: implement image_picker for receipt upload
                  Container(
                    width: double.infinity,
                    height: 110,
                    child: CustomPaint(
                      painter: _DashedBorderPainter(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0663FF), Color(0xFF003CC1)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                        // TODO: implement add expense backend logic
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_circle_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add Expense',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
                    'Add New Expense',
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

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D0D0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFFE8F4FF),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF9E9E9E)),
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF2C2C2C),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
  value: item,
  child: Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF0663FF),
            width: 2,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(item, style: GoogleFonts.montserrat(fontSize: 13)),
    ],
  ),
);
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
} 

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0D0D0)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const radius = Radius.circular(10);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final path = Path()..addRRect(rrect);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}