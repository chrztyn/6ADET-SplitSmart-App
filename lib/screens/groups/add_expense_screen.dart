import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? _selectedPayerId;
  String? _selectedPayerName;
  List<Map<String, dynamic>> _members = [];
  List<String> _selectedSplitIds = [];
  bool _splitAll = true;
  DateTime _selectedDate = DateTime.now();
  File? _receiptFile;
  bool _isLoading = false;
  bool _loadingMembers = true;
  String _selectedCategory = 'food';
  final List<String> _categories = [
    'food',
    'rent',
    'transport',
    'utilities',
    'entertainment',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final provider = context.read<AppProvider>();
      final group = await provider.getGroup(widget.groupId);
      final members =
          (group['members'] as List?)
              ?.map((m) => m['user'] as Map<String, dynamic>)
              .where((u) => u['id'] != null)
              .toList() ??
          [];

      final currentUserId = provider.profile?['id'] as String?;
      final currentUserName = provider.profile?['name'] as String?;

      // Patch current user's name using the resolved provider name when
      // profiles.name is null (e.g. name was only stored in user_metadata)
      final patchedMembers = members.map((m) {
        if (m['id'] == currentUserId &&
            (m['name'] == null || (m['name'] as String).trim().isEmpty)) {
          return {...m, 'name': currentUserName};
        }
        return m;
      }).toList();

      setState(() {
        _members = patchedMembers;
        _selectedSplitIds = patchedMembers
            .map((m) => m['id'] as String)
            .toList();
        // Default payer = current user
        final me = patchedMembers.firstWhere(
          (m) => m['id'] == currentUserId,
          orElse: () => patchedMembers.isNotEmpty ? patchedMembers[0] : {},
        );
        if (me.isNotEmpty) {
          _selectedPayerId = me['id'] as String;
          _selectedPayerName = me['name'] as String?;
        }
        _loadingMembers = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0663FF)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _receiptFile = File(picked.path));
  }

  Future<void> _addExpense() async {
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please enter a description');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }
    if (_selectedPayerId == null) {
      _showError('Please select who paid');
      return;
    }
    if (_selectedSplitIds.isEmpty) {
      _showError('Please select at least one person to split with');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AppProvider>().addExpense(
        groupId: widget.groupId,
        description: _descriptionController.text.trim(),
        amount: amount,
        paidByUserId: _selectedPayerId!,
        splitBetween: _selectedSplitIds,
        category: _selectedCategory,
        date: _selectedDate,
        receiptFile: _receiptFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense added! 🎉', style: GoogleFonts.montserrat()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // returns true to trigger refresh
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.montserrat()),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loadingMembers
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Description*'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _descriptionController,
                          hint: 'e.g. Dinner, Groceries',
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Amount*'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _amountController,
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          prefix: 'PHP ',
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Who Paid*'),
                        const SizedBox(height: 8),
                        _buildMemberDropdown(),
                        const SizedBox(height: 20),

                        _buildLabel('Split Between*'),
                        const SizedBox(height: 8),
                        _buildSplitSection(),
                        const SizedBox(height: 20),

                        _buildLabel('Category'),
                        const SizedBox(height: 8),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 20),

                        _buildLabel('Date'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD0D0D0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    color: const Color(0xFF2C2C2C),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Color(0xFF9E9E9E),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Upload Image Receipt'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickReceipt,
                          child: Container(
                            width: double.infinity,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFFF5F5F5),
                            ),
                            child: _receiptFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _receiptFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : CustomPaint(
                                    painter: _DashedBorderPainter(),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.upload_outlined,
                                            color: Color(0xFF9E9E9E),
                                            size: 28,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Tap to upload receipt',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 12,
                                              color: const Color(0xFF9E9E9E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
                              onTap: _isLoading ? null : _addExpense,
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D0D0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: const Color(0xFFE8F4FF),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF9E9E9E)),
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF2C2C2C),
          ),
          items: _categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat,
              child: Text(
                cat[0].toUpperCase() + cat.substring(1),
                style: GoogleFonts.montserrat(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedCategory = val ?? 'food');
          },
        ),
      ),
    );
  }

  // who paid dropdown
  Widget _buildMemberDropdown() {
    if (_members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD0D0D0)),
        ),
        child: Text(
          'No members found',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF9E9E9E),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D0D0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPayerId,
          isExpanded: true,
          dropdownColor: const Color(0xFFE8F4FF),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF9E9E9E)),
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF2C2C2C),
          ),
          items: _members.map((member) {
            return DropdownMenuItem<String>(
              value: member['id'] as String,
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
                  Text(
                    member['name'] ?? 'Unknown',
                    style: GoogleFonts.montserrat(fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            final member = _members.firstWhere((m) => m['id'] == val);
            setState(() {
              _selectedPayerId = val;
              _selectedPayerName = member['name'] as String?;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSplitSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D0D0), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: _splitAll,
                activeColor: const Color(0xFF0663FF),
                onChanged: (val) {
                  setState(() {
                    _splitAll = val ?? true;
                    _selectedSplitIds = _splitAll
                        ? _members.map((m) => m['id'] as String).toList()
                        : [];
                  });
                },
              ),
              Text(
                'All Members',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          ..._members.map((member) {
            final id = member['id'] as String;
            final isSelected = _selectedSplitIds.contains(id);
            return Row(
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: const Color(0xFF0663FF),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedSplitIds.add(id);
                      } else {
                        _selectedSplitIds.remove(id);
                      }
                      _splitAll = _selectedSplitIds.length == _members.length;
                    });
                  },
                ),
                Text(
                  member['name'] ?? 'Unknown',
                  style: GoogleFonts.montserrat(fontSize: 13),
                ),
              ],
            );
          }),
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
                    'Add Expense · ${widget.groupName}',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
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
    String hint = '',
    String prefix = '',
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        color: const Color(0xFF2C2C2C),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          fontSize: 13,
          color: const Color(0xFF9E9E9E),
        ),
        prefixText: prefix,
        prefixStyle: GoogleFonts.montserrat(
          fontSize: 13,
          color: const Color(0xFF2C2C2C),
        ),
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
