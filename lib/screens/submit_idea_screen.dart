import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _purple        = Color(0xFF7C3AED);
const _purpleLight   = Color(0xFF8B5CF6);
const _gradientStart = Color(0xFF7C3AED);
const _gradientEnd   = Color(0xFF3B82F6);
const _bgColor       = Color(0xFFF8FAFC);

const _categories = [
  'Food', 'AI', 'Automobile', 'Healthcare',
  'Blockchain', 'IoT', 'Sustainability',
];

// ─── SubmitIdeaScreen ─────────────────────────────────────────────────────────
class SubmitIdeaScreen extends StatefulWidget {
  const SubmitIdeaScreen({super.key});

  @override
  State<SubmitIdeaScreen> createState() => _SubmitIdeaScreenState();
}

class _SubmitIdeaScreenState extends State<SubmitIdeaScreen> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final _titleController     = TextEditingController();
  final _problemController   = TextEditingController();
  final _solutionController  = TextEditingController();
  final _basePriceController = TextEditingController();

  // form state
  String?    _selectedCategory;
  bool?      _patentAvailable;
  DateTime?  _selectedDate;
  TimeOfDay? _selectedTime;
  bool       _submitting = false;

  // ── AI price state ────────────────────────────────────────────────────────
  bool   _aiLoading       = false;
  bool   _aiPriceRevealed = false;
  String _aiLoadingMessage = '';

  final List<String> _aiMessages = [
    '🔍 Analyzing your idea\'s uniqueness...',
    '📊 Scanning current market conditions...',
    '🌍 Estimating total addressable market size...',
    '🏆 Benchmarking against similar patented ideas...',
    '⚡ Running competitor pricing analysis...',
    '🤖 Calculating optimal base price...',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _problemController.dispose();
    _solutionController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  // ── date picker ───────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _purple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── time picker ───────────────────────────────────────────────────────────
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _purple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── AI price fetch ────────────────────────────────────────────────────────
  Future<void> _getAISuggestedPrice() async {
    if (_aiLoading || _aiPriceRevealed) return;
    setState(() {
      _aiLoading = true;
      _aiLoadingMessage = _aiMessages[0];
    });

    // Cycle through messages every ~2.5 seconds (~15s total)
    for (int i = 1; i < _aiMessages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;
      setState(() => _aiLoadingMessage = _aiMessages[i]);
    }

    // Small pause after last message before revealing price
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    setState(() {
      _aiLoading = false;
      _aiPriceRevealed = true;
    });
  }

  // ── submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('Please select a category.');
      return;
    }
    if (_patentAvailable == null) {
      _showError('Please select patent availability.');
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showError('Please set a bidding schedule.');
      return;
    }

    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() => _submitting = false);

    if (!mounted) return;
    _showSuccess();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_gradientStart, _gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child:
                const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Idea Submitted!',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827))),
              const SizedBox(height: 8),
              Text(
                'Your idea has been submitted for review. We\'ll notify you once it\'s approved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_gradientStart, _gradientEnd],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Back to Home',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  // ── Idea Title ─────────────────────────────────────────
                  _FieldLabel(text: 'Idea Title', required: true),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _titleController,
                    hint: 'Enter your innovative idea title',
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Problem Statement ──────────────────────────────────
                  _FieldLabel(text: 'Problem Statement', required: true),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _problemController,
                    hint: 'What problem does your idea solve?',
                    maxLines: 5,
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Detailed Statement & Solution ──────────────────────
                  _FieldLabel(
                      text: 'Detailed Statement & Solution', required: true),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _solutionController,
                    hint: 'Describe your solution in detail...',
                    maxLines: 7,
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Category ───────────────────────────────────────────
                  _FieldLabel(text: 'Category', required: true),
                  const SizedBox(height: 10),
                  _buildCategorySelector(),
                  const SizedBox(height: 20),

                  // ── Patent Available ───────────────────────────────────
                  _FieldLabel(text: 'Patent Available?', required: true),
                  const SizedBox(height: 10),
                  _buildPatentToggle(),
                  const SizedBox(height: 20),

                  // ── Base Price ─────────────────────────────────────────
                  _FieldLabel(text: 'Base Price (USD)', required: true),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _basePriceController,
                    hint: 'Enter your expected base price',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // ── AI Suggested Price (interactive) ───────────────────
                  _buildAISuggestedCard(),
                  const SizedBox(height: 20),

                  // ── Bidding Schedule ───────────────────────────────────
                  _FieldLabel(text: 'Bidding Schedule', required: true),
                  const SizedBox(height: 10),
                  _buildBiddingSchedule(),
                  const SizedBox(height: 32),

                  // ── Submit button ──────────────────────────────────────
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Color(0xFF374151), size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              'Submit Your Idea',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Generic text field ────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: const Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  // ── Category selector ─────────────────────────────────────────────────────
  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(
                  () => _selectedCategory = isSelected ? null : cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color:
              isSelected ? _purple.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color:
                isSelected ? _purple : const Color(0xFFD1D5DB),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              cat,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? _purple
                    : const Color(0xFF374151),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Patent Yes / No toggle ────────────────────────────────────────────────
  Widget _buildPatentToggle() {
    return Row(
      children: [
        _PatentOption(
          label: 'Yes',
          selected: _patentAvailable == true,
          onTap: () => setState(() => _patentAvailable = true),
        ),
        const SizedBox(width: 12),
        _PatentOption(
          label: 'No',
          selected: _patentAvailable == false,
          onTap: () => setState(() => _patentAvailable = false),
        ),
      ],
    );
  }

  // ── AI Suggested Price — interactive ─────────────────────────────────────
  Widget _buildAISuggestedCard() {
    // ── State 1: Not yet triggered — show the button ──────────────────
    if (!_aiLoading && !_aiPriceRevealed) {
      return GestureDetector(
        onTap: _getAISuggestedPrice,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: _purple.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _purple.withOpacity(0.4), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: _purple, size: 18),
              const SizedBox(width: 8),
              Text(
                'Get AI Suggested Price',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _purple,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── State 2: Loading — show progress + cycling messages ───────────
    if (_aiLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _purple.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _purple.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: _purple, size: 16),
                const SizedBox(width: 6),
                Text(
                  'AI is analyzing your idea...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                backgroundColor: Color(0xFFEDE9FE),
                valueColor:
                AlwaysStoppedAnimation<Color>(_purple),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                _aiLoadingMessage,
                key: ValueKey(_aiLoadingMessage),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: _purple.withOpacity(0.85),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── State 3: Price revealed ───────────────────────────────────────
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purple.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: _purple, size: 18),
              const SizedBox(width: 6),
              Text(
                'AI Suggested Price',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _purple,
                ),
              ),
              const Spacer(),
              // Refresh — lets user re-run
              GestureDetector(
                onTap: () => setState(() {
                  _aiPriceRevealed = false;
                  _aiLoading = false;
                }),
                child: const Icon(Icons.refresh, color: _purple, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$50,000',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _purple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on: idea uniqueness, market conditions, market size & competitor pricing',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: _purple.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bidding Schedule ──────────────────────────────────────────────────────
  Widget _buildBiddingSchedule() {
    final dateText = _selectedDate != null
        ? '${_selectedDate!.day.toString().padLeft(2, '0')}-'
        '${_selectedDate!.month.toString().padLeft(2, '0')}-'
        '${_selectedDate!.year}'
        : 'dd-mm-yyyy';

    final timeText = _selectedTime != null
        ? _selectedTime!.format(context)
        : '--:--';

    return Row(
      children: [
        // Date picker
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  Text(
                    dateText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: _selectedDate != null
                          ? const Color(0xFF111827)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Time picker
        Expanded(
          child: GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_outlined,
                      size: 16, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  Text(
                    timeText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: _selectedTime != null
                          ? const Color(0xFF111827)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_gradientStart, _gradientEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextButton(
          onPressed: _submitting ? null : _submit,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _submitting
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white),
          )
              : Text(
            'Submit Idea for Review',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool   required;
  const _FieldLabel({required this.text, this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937)),
        children: required
            ? [
          const TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.redAccent),
          )
        ]
            : [],
      ),
    );
  }
}

// ─── Patent Option Button ─────────────────────────────────────────────────────
class _PatentOption extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;
  const _PatentOption(
      {required this.label,
        required this.selected,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 50,
          decoration: BoxDecoration(
            color:
            selected ? _purple.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _purple : const Color(0xFFD1D5DB),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
                color:
                selected ? _purple : const Color(0xFF374151),
              ),
            ),
          ),
        ),
      ),
    );
  }
}