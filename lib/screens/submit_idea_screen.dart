import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ml_service.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _categories = [
  'Food', 'AI', 'Automobile', 'Healthcare',
  'Blockchain', 'IoT', 'Sustainability',
];

// Max patent image size: 150 KB
const int _maxPatentBytes = 150 * 1024;

// ─── SubmitIdeaScreen ─────────────────────────────────────────────────────────
class SubmitIdeaScreen extends StatefulWidget {
  const SubmitIdeaScreen({super.key});

  @override
  State<SubmitIdeaScreen> createState() => _SubmitIdeaScreenState();
}

class _SubmitIdeaScreenState extends State<SubmitIdeaScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────────────────────
  final _titleController     = TextEditingController();
  final _problemController   = TextEditingController();
  final _solutionController  = TextEditingController();
  final _basePriceController = TextEditingController();

  // ── Form state ────────────────────────────────────────────────────────────
  String?    _selectedCategory;
  bool?      _patentAvailable;
  DateTime?  _selectedDate;
  TimeOfDay? _selectedTime;
  bool       _submitting = false;

  // ── Patent image ──────────────────────────────────────────────────────────
  File?   _patentImageFile;
  String? _patentImageBase64;
  final   ImagePicker _imagePicker = ImagePicker();

  // ── AI price state ────────────────────────────────────────────────────────
  bool   _aiLoading        = false;
  bool   _aiPriceRevealed  = false;
  String _aiLoadingMessage = '';
  
  Map<String, dynamic>? _mlResult;
  bool _fetchingSimilar = false;

  final List<String> _aiMessages = [
    '🔍 Analyzing your idea\'s uniqueness...',
    '📊 Scanning current market conditions...',
    '🌍 Estimating total addressable market size...',
    '🏆 Benchmarking against similar patented ideas...',
    '⚡ Running competitor pricing analysis...',
    '🤖 Calculating optimal base price...',
  ];

  // ── Firebase ──────────────────────────────────────────────────────────────
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _titleController.dispose();
    _problemController.dispose();
    _solutionController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  // ── Date picker ───────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now    = DateTime.now();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: colorScheme.copyWith(primary: colorScheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Time picker ───────────────────────────────────────────────────────────
  Future<void> _pickTime() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: colorScheme.copyWith(primary: colorScheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Pick patent image ─────────────────────────────────────────────────────
  Future<void> _pickPatentImage() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Upload Patent Document',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text('Max file size: 150 KB',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: colorScheme.primary),
                title: Text('Choose from Gallery',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: colorScheme.onSurface)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined,
                    color: colorScheme.primary),
                title: Text('Take a Photo',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: colorScheme.onSurface)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 40,
      maxWidth: 700,
      maxHeight: 700,
    );

    if (picked == null || !mounted) return;

    final file  = File(picked.path);
    final bytes = await file.readAsBytes();

    if (bytes.length > _maxPatentBytes) {
      _showError(
        'Image is ${(bytes.length / 1024).toStringAsFixed(0)} KB — '
            'please use an image under 150 KB.',
      );
      return;
    }

    setState(() {
      _patentImageFile   = file;
      _patentImageBase64 = base64Encode(bytes);
    });

    const Color successGreen = Color(0xFF16A34A);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Patent image selected (${(bytes.length / 1024).toStringAsFixed(0)} KB)',
        style: GoogleFonts.plusJakartaSans(fontSize: 13),
      ),
      backgroundColor: successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── AI price fetch ────────────────────────────────────────────────────────
  Future<void> _getAISuggestedPrice() async {
    if (_aiLoading || _aiPriceRevealed) return;
    
    // Check if we already have ML results from problem statement submission
    if (_mlResult == null) {
      setState(() {
        _aiLoading = true;
        _aiLoadingMessage = "Analyzing idea for pricing...";
      });
      final result = await MLService().processIdea(_problemController.text);
      if (result != null) {
        setState(() => _mlResult = result);
      }
    }

    setState(() {
      _aiLoading        = true;
      _aiLoadingMessage = _aiMessages[0];
    });

    for (int i = 1; i < _aiMessages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _aiLoadingMessage = _aiMessages[i]);
    }

    if (!mounted) return;
    setState(() {
      if (_mlResult != null && _mlResult!['suggested_price'] != null) {
         _basePriceController.text = _mlResult!['suggested_price'].toString();
      }
      _aiLoading        = false;
      _aiPriceRevealed  = true;
    });
  }

  Future<void> _fetchSimilarIdeas() async {
    final text = _problemController.text.trim();
    if (text.isEmpty) {
      _showError('Please enter a problem statement first.');
      return;
    }

    setState(() => _fetchingSimilar = true);
    try {
      final result = await MLService().processIdea(text);
      if (!mounted) return;
      setState(() {
        _mlResult = result;
        _fetchingSimilar = false;
        if (result == null) {
          _showError('Similarity check failed check your connection');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _fetchingSimilar = false);
        _showError('An error occurred during similarity analysis.');
      }
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
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
    if (_patentAvailable == true && _patentImageBase64 == null) {
      _showError('Please upload your patent document.');
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showError('Please set a bidding schedule.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final uid = _auth.currentUser?.uid;

      final Map<String, dynamic> ideaData = {
        'uid':              uid,
        'title':            _titleController.text.trim(),
        'problemStatement': _problemController.text.trim(),
        'detailedSolution': _solutionController.text.trim(),
        'category':         _selectedCategory,
        'isPatented':       _patentAvailable,
        'basePrice':        int.tryParse(_basePriceController.text.trim()) ?? 0,
        'biddingDate':      _selectedDate != null
            ? '${_selectedDate!.day.toString().padLeft(2, '0')}-'
            '${_selectedDate!.month.toString().padLeft(2, '0')}-'
            '${_selectedDate!.year}'
            : null,
        'biddingTime':      _selectedTime?.format(context),
        'status':           'pending_review',
        // FIX: Added client-side integer timestamp used for sorting in admin screen.
        // FieldValue.serverTimestamp() is async and arrives null briefly,
        // which breaks orderBy. 'createdAt' (int ms) is available immediately.
        'createdAt':        DateTime.now().millisecondsSinceEpoch,
        'submittedAt':      FieldValue.serverTimestamp(),
      };

      if (_aiPriceRevealed) {
        ideaData['aiSuggestedPrice'] = _mlResult?['suggested_price'] ?? 50000;
      }

      if (_patentAvailable == true && _patentImageBase64 != null) {
        ideaData['patentImageBase64'] = _patentImageBase64;
      }

      if (uid != null) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('ideas')
            .add(ideaData);
      }

      setState(() => _submitting = false);
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      setState(() => _submitting = false);
      _showError('Failed to submit: $e');
    }
  }

  void _showError(String msg) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: colorScheme.onErrorContainer)),
      backgroundColor: colorScheme.errorContainer,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showSuccess() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.check,
                    color: colorScheme.onPrimary, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Idea Submitted!',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(
                'Your idea has been submitted for review. '
                    'We\'ll notify you once it\'s approved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Back to Home',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerLow,
      body: Column(
        children: [
          _buildAppBar(colorScheme),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  // ── Idea Title ─────────────────────────────────────────
                  _FieldLabel(text: 'Idea Title', required: true, colorScheme: colorScheme),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _titleController,
                    hint: 'Enter your innovative idea title',
                    colorScheme: colorScheme,
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Problem Statement ──────────────────────────────────
                  _FieldLabel(
                      text: 'Problem Statement', required: true, colorScheme: colorScheme),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _problemController,
                    hint: 'What problem does your idea solve?',
                    colorScheme: colorScheme,
                    maxLines: 5,
                    onChanged: (v) {
                       // Optional: Trigger similarity search when text is long enough or on focus lost
                    },
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  _buildSimilarityTrigger(colorScheme),
                  if (_fetchingSimilar || _mlResult != null)
                    _buildMLSimilaritySection(colorScheme),
                  const SizedBox(height: 20),

                  // ── Detailed Statement & Solution ──────────────────────
                  _FieldLabel(
                      text: 'Detailed Statement & Solution',
                      required: true, colorScheme: colorScheme),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _solutionController,
                    hint: 'Describe your solution in detail...',
                    colorScheme: colorScheme,
                    maxLines: 7,
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Category ───────────────────────────────────────────
                  _FieldLabel(text: 'Category', required: true, colorScheme: colorScheme),
                  const SizedBox(height: 10),
                  _buildCategorySelector(colorScheme),
                  const SizedBox(height: 20),

                  // ── Patent Available ───────────────────────────────────
                  _FieldLabel(
                      text: 'Patent Available?', required: true, colorScheme: colorScheme),
                  const SizedBox(height: 10),
                  _buildPatentToggle(colorScheme),
                  const SizedBox(height: 12),

                  // ── Patent image upload (only when Yes) ────────────────
                  if (_patentAvailable == true)
                    _buildPatentUploadSection(colorScheme),

                  const SizedBox(height: 20),

                  // ── Base Price ─────────────────────────────────────────
                  _FieldLabel(
                      text: 'Base Price (USD)', required: true, colorScheme: colorScheme),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _basePriceController,
                    hint: 'Enter your expected base price',
                    colorScheme: colorScheme,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // ── AI Suggested Price ─────────────────────────────────
                  _buildAISuggestedCard(colorScheme),
                  const SizedBox(height: 20),

                  // ── Bidding Schedule ───────────────────────────────────
                  _FieldLabel(
                      text: 'Bidding Schedule', required: true, colorScheme: colorScheme),
                  const SizedBox(height: 10),
                  _buildBiddingSchedule(colorScheme),
                  const SizedBox(height: 32),

                  // ── Submit button ──────────────────────────────────────
                  _buildSubmitButton(colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar(ColorScheme colorScheme) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: colorScheme.surface,
        padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back,
                  color: colorScheme.onSurface, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              'Submit Your Idea',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
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
    required ColorScheme colorScheme,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
    );
  }

  // ── Category selector ─────────────────────────────────────────────────────
  Widget _buildCategorySelector(ColorScheme colorScheme) {
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
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.12)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
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
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Patent Yes / No toggle ────────────────────────────────────────────────
  Widget _buildPatentToggle(ColorScheme colorScheme) {
    return Row(
      children: [
        _PatentOption(
          label: 'Yes',
          selected: _patentAvailable == true,
          colorScheme: colorScheme,
          onTap: () => setState(() {
            _patentAvailable = true;
          }),
        ),
        const SizedBox(width: 12),
        _PatentOption(
          label: 'No',
          selected: _patentAvailable == false,
          colorScheme: colorScheme,
          onTap: () => setState(() {
            _patentAvailable    = false;
            _patentImageFile   = null;
            _patentImageBase64 = null;
          }),
        ),
      ],
    );
  }

  // ── Patent image upload section ───────────────────────────────────────────
  Widget _buildPatentUploadSection(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color goldStandard = Color(0xFFFBBF24);
    const Color successGreen = Color(0xFF16A34A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark 
                ? goldStandard.withOpacity(0.1) 
                : goldStandard.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: goldStandard.withOpacity(isDark ? 0.3 : 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: isDark ? goldStandard : const Color(0xFFD97706), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please upload a clear photo of your patent certificate. '
                      'Max size: 150 KB (compressed JPG recommended).',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? goldStandard : const Color(0xFF92400E),
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),

        RichText(
          text: TextSpan(
            text: 'Patent Document',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: colorScheme.error),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: _pickPatentImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            decoration: BoxDecoration(
              color: _patentImageFile != null
                  ? colorScheme.primary.withOpacity(0.08)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _patentImageFile != null
                    ? colorScheme.primary.withOpacity(0.4)
                    : colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: _patentImageFile != null
                ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.file(
                    _patentImageFile!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.scrim.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.edit,
                        color: colorScheme.onPrimary, size: 14),
                  ),
                ),
                Positioned(
                  bottom: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: successGreen.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check,
                            color: colorScheme.onPrimary, size: 12),
                        const SizedBox(width: 4),
                        Text('Patent uploaded',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimary)),
                      ],
                    ),
                  ),
                ),
              ],
            )
                : Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(Icons.upload_file_outlined,
                      size: 36, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 10),
                  Text('Upload Patent Certificate',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('JPG / PNG  •  Max 150 KB',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarityTrigger(ColorScheme colorScheme) {
    if (_fetchingSimilar) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _fetchSimilarIdeas,
        icon: Icon(Icons.compare_arrows, size: 16, color: colorScheme.primary),
        label: Text('Check Similarity', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
      ),
    );
  }

  Widget _buildMLSimilaritySection(ColorScheme colorScheme) {
    if (_fetchingSimilar) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text('Analyzing similarity...', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (_mlResult == null) return const SizedBox.shrink();

    final status = _mlResult!['similarity_status'] ?? 'Unknown';
    final similarIdeas = (_mlResult!['similar_ideas'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text('Similarity Status: ', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(status, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _getSimilarityColor(status, colorScheme), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Top Similar Ideas:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...similarIdeas.take(3).map((idea) => Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb, size: 14, color: colorScheme.secondary.withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(child: Text(idea['idea'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 12))),
                const SizedBox(width: 4),
                Text('${((idea['score'] ?? 0) * 100).toStringAsFixed(0)}%', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: colorScheme.primary)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getSimilarityColor(String status, ColorScheme colorScheme) {
    if (status.toLowerCase().contains('high')) return Colors.red;
    if (status.toLowerCase().contains('moderate')) return Colors.orange;
    return Colors.green;
  }

  // ── AI Suggested Price ────────────────────────────────────────────────────
  Widget _buildAISuggestedCard(ColorScheme colorScheme) {
    if (!_aiLoading && !_aiPriceRevealed) {
      return GestureDetector(
        onTap: _getAISuggestedPrice,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: colorScheme.primary.withOpacity(0.4), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome,
                  color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Get AI Suggested Price',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_aiLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: colorScheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'AI is analyzing your idea...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
                valueColor:
                AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) =>
                  FadeTransition(
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
                  color: colorScheme.primary.withOpacity(0.85),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Revealed
    final suggestedPrice = _mlResult != null && _mlResult!['suggested_price'] != null
        ? '\$${_mlResult!['suggested_price'].toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}'
        : '\$50,000';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: colorScheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'AI Suggested Price',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _aiPriceRevealed = false;
                  _aiLoading       = false;
                }),
                child: Icon(Icons.refresh,
                    color: colorScheme.primary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(suggestedPrice,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary)),
          const SizedBox(height: 4),
          Text(
            'Based on: idea uniqueness, market conditions, '
                'market size & competitor pricing',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: colorScheme.primary.withOpacity(0.8),
                height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── Bidding Schedule ──────────────────────────────────────────────────────
  Widget _buildBiddingSchedule(ColorScheme colorScheme) {
    final dateText = _selectedDate != null
        ? '${_selectedDate!.day.toString().padLeft(2, '0')}-'
        '${_selectedDate!.month.toString().padLeft(2, '0')}-'
        '${_selectedDate!.year}'
        : 'dd-mm-yyyy';

    final timeText =
    _selectedTime != null ? _selectedTime!.format(context) : '--:--';

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(dateText,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: _selectedDate != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(timeText,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: _selectedTime != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextButton(
          onPressed: _submitting ? null : _submit,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _submitting
              ? SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: colorScheme.onPrimary))
              : Text('Submit Idea for Review',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool   required;
  final ColorScheme colorScheme;
  const _FieldLabel({required this.text, this.required = false, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface),
        children: required
            ? [
          TextSpan(
              text: ' *',
              style: TextStyle(color: colorScheme.error))
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
  final ColorScheme  colorScheme;
  const _PatentOption(
      {required this.label,
        required this.selected,
        required this.onTap,
        required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 50,
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withOpacity(0.1)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outlineVariant,
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
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

