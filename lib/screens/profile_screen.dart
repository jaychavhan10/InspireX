import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _domains = [
  'Food', 'AI', 'Automobile', 'Healthcare',
  'Blockchain', 'IoT', 'Sustainability', 'FinTech',
];

// ── 4 built-in avatars (gradient combos + icon) ───────────────────────────────
List<Map<String, dynamic>> _getAvatarOptions(ColorScheme colorScheme) => [
  {'bg': [colorScheme.primary, colorScheme.secondary], 'icon': Icons.person},
  {'bg': [colorScheme.tertiary, colorScheme.secondary], 'icon': Icons.person},
  {'bg': [colorScheme.primary, colorScheme.tertiary], 'icon': Icons.person},
  {'bg': [colorScheme.secondary, colorScheme.primary], 'icon': Icons.person},
];

enum _AccountType { contributor, investor, both }

// ─── ProfileScreen ────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Text controllers ───────────────────────────────────────────────────────
  final _nameController        = TextEditingController();
  final _emailController       = TextEditingController();
  final _phoneController       = TextEditingController();
  final _locationController    = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscController        = TextEditingController();
  final _bankNameController    = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  // ── Avatar index (0–3) ────────────────────────────────────────────────────
  int _selectedAvatar = 0;

  // ── ID docs: local File picks + saved Base64 ──────────────────────────────
  File?   _newAadhaarFile;
  File?   _newPanFile;
  String? _aadhaarBase64;
  String? _panBase64;

  // ── Other state ───────────────────────────────────────────────────────────
  _AccountType      _accountType     = _AccountType.contributor;
  final Set<String> _selectedDomains = {};

  bool _loading = true;
  bool _saving  = false;

  // ── Firebase ──────────────────────────────────────────────────────────────
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String get _uid => _auth.currentUser!.uid;

  // Max allowed size for ID docs in bytes (150 KB is safe for Firestore)
  static const int _maxDocBytes = 150 * 1024; // 150 KB

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  // ── Load profile from Firestore ───────────────────────────────────────────
  Future<void> _loadProfile() async {
    try {
      final doc =
      await _firestore.collection('users').doc(_uid).get();

      if (!doc.exists || !mounted) {
        setState(() => _loading = false);
        return;
      }

      final data = doc.data()!;

      _nameController.text        = data['fullName']    ?? '';
      _emailController.text       = data['email']       ?? '';
      _phoneController.text       = data['mobile']      ?? '';
      _locationController.text    = data['location']    ?? '';
      _bankAccountController.text = data['bankAccount'] ?? '';
      _ifscController.text        = data['ifsc']        ?? '';
      _bankNameController.text    = data['bankName']    ?? '';

      // Avatar index
      _selectedAvatar =
          (data['avatarIndex'] as int?) ?? 0;

      // Role
      final roleStr = data['role'] as String? ?? 'contributor';
      _accountType = _AccountType.values.firstWhere(
            (e) => e.name == roleStr,
        orElse: () => _AccountType.contributor,
      );

      // Domains
      _selectedDomains
        ..clear()
        ..addAll(List<String>.from(data['domains'] ?? []));

      // ID doc Base64 strings
      final rawAadhaar = data['aadhaarBase64'];
      final rawPan     = data['panBase64'];
      _aadhaarBase64   =
      (rawAadhaar is String && rawAadhaar.isNotEmpty)
          ? rawAadhaar
          : null;
      _panBase64       =
      (rawPan is String && rawPan.isNotEmpty) ? rawPan : null;

      debugPrint(
          '[Profile] aadhaar=${_aadhaarBase64 != null} pan=${_panBase64 != null}');
    } catch (e) {
      debugPrint('[Profile] load error: $e');
      _showSnack('Failed to load profile. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── File → Base64, with size check ───────────────────────────────────────
  Future<String?> _fileToBase64Checked(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxDocBytes) {
      return null; // caller will show error
    }
    return base64Encode(bytes);
  }

  // ── Base64 → MemoryImage ──────────────────────────────────────────────────
  MemoryImage? _base64ToImage(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      final cleaned = b64.replaceAll(RegExp(r'\s'), '');
      final bytes   = base64Decode(cleaned);
      if (bytes.isEmpty) return null;
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint('[Profile] base64 decode error: $e');
      return null;
    }
  }

  // ── Save to Firestore ─────────────────────────────────────────────────────
  Future<void> _saveChanges(ColorScheme colorScheme) async {
    setState(() => _saving = true);

    try {
      // Process Aadhaar
      if (_newAadhaarFile != null) {
        final b64 = await _fileToBase64Checked(_newAadhaarFile!);
        if (b64 == null) {
          setState(() => _saving = false);
          _showSnack(
              'Aadhaar image is too large. Please use an image under 150 KB.');
          return;
        }
        _aadhaarBase64  = b64;
        _newAadhaarFile = null;
      }

      // Process PAN
      if (_newPanFile != null) {
        final b64 = await _fileToBase64Checked(_newPanFile!);
        if (b64 == null) {
          setState(() => _saving = false);
          _showSnack(
              'PAN image is too large. Please use an image under 150 KB.');
          return;
        }
        _panBase64  = b64;
        _newPanFile = null;
      }

      final Map<String, dynamic> updateData = {
        'fullName':    _nameController.text.trim(),
        'email':       _emailController.text.trim(),
        'mobile':      _phoneController.text.trim(),
        'location':    _locationController.text.trim(),
        'bankAccount': _bankAccountController.text.trim(),
        'ifsc':        _ifscController.text.trim(),
        'bankName':    _bankNameController.text.trim(),
        'role':        _accountType.name,
        'domains':     _selectedDomains.toList(),
        'avatarIndex': _selectedAvatar,
        'updatedAt':   FieldValue.serverTimestamp(),
      };

      if (_aadhaarBase64 != null) {
        updateData['aadhaarBase64'] = _aadhaarBase64;
      }
      if (_panBase64 != null) {
        updateData['panBase64'] = _panBase64;
      }

      await _firestore
          .collection('users')
          .doc(_uid)
          .set(updateData, SetOptions(merge: true));

      setState(() => _saving = false);
      _showSnack('Profile saved successfully!', color: colorScheme.primary);
    } catch (e) {
      debugPrint('[Profile] save error: $e');
      setState(() => _saving = false);
      _showSnack('Failed to save. Please try again.');
    }
  }

  // ── Avatar picker bottom sheet ────────────────────────────────────────────
  void _showAvatarPicker(ColorScheme colorScheme) {
    final avatarOptions = _getAvatarOptions(colorScheme);
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 32, height: 4,
              decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text('Choose your Avatar',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text('Pick one of the avatars below',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(avatarOptions.length, (i) {
                final colors = avatarOptions[i]['bg'] as List<Color>;
                final isSelected = _selectedAvatar == i;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAvatar = i);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: isSelected
                          ? Border.all(
                          color: colorScheme.primary,
                          width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: colors.first.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                          : [],
                    ),
                    child: Icon(
                      avatarOptions[i]['icon'] as IconData,
                      color: colorScheme.onPrimary,
                      size: 30,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Document picker ───────────────────────────────────────────────────────
  Future<void> _pickDocument(bool isAadhaar, ColorScheme colorScheme) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text(
                  'Upload ${isAadhaar ? 'Aadhaar' : 'PAN'} Card',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text('Max file size: 150 KB',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: colorScheme.primary, size: 20),
                title: Text('Choose from Gallery',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: colorScheme.onSurface)),
                onTap: () =>
                    Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined,
                    color: colorScheme.primary, size: 20),
                title: Text('Take a Photo',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: colorScheme.onSurface)),
                onTap: () =>
                    Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    // Pick with aggressive compression to stay under 150 KB
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 40,
      maxWidth: 700,
      maxHeight: 700,
    );

    if (picked == null || !mounted) return;

    final file  = File(picked.path);
    final bytes = await file.readAsBytes();

    // Pre-check size before even setting state
    if (bytes.length > _maxDocBytes) {
      _showSnack(
          'Image is ${(bytes.length / 1024).toStringAsFixed(0)} KB — '
              'please use one under 150 KB.',
          color: colorScheme.error);
      return;
    }

    setState(() {
      if (isAadhaar) {
        _newAadhaarFile = file;
      } else {
        _newPanFile = file;
      }
    });

    _showSnack(
        '${isAadhaar ? 'Aadhaar' : 'PAN'} selected '
            '(${(bytes.length / 1024).toStringAsFixed(0)} KB). '
            'Tap Save Changes to store it.',
        color: Colors.green);
  }

  void _showSnack(String msg, {Color? color}) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: colorScheme.onInverseSurface)),
      backgroundColor: color ?? colorScheme.inverseSurface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark      = theme.brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
            child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerLow,
      body: Column(
        children: [
          _buildAppBar(colorScheme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
              children: [
                _buildAvatarSection(colorScheme),
                const SizedBox(height: 16),
                _buildSectionCard(
                  icon: Icons.person_outline,
                  title: 'Personal Details',
                  colorScheme: colorScheme,
                  child: _buildPersonalDetails(colorScheme),
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  icon: Icons.shield_outlined,
                  title: 'ID Verification',
                  colorScheme: colorScheme,
                  child: _buildIDVerification(colorScheme, isDark),
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  icon: Icons.credit_card_outlined,
                  title: 'KYC Details',
                  colorScheme: colorScheme,
                  child: _buildKYCDetails(colorScheme, isDark),
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  icon: Icons.work_outline,
                  title: 'Account Type',
                  colorScheme: colorScheme,
                  child: _buildAccountType(colorScheme),
                ),
                const SizedBox(height: 12),
                _buildDomainsCard(colorScheme),
                const SizedBox(height: 20),
                _buildSaveButton(colorScheme),
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back,
                  color: colorScheme.onSurface, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            Text('Profile & Settings',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  // ── Avatar section ────────────────────────────────────────────────────────
  Widget _buildAvatarSection(ColorScheme colorScheme) {
    final avatarOptions = _getAvatarOptions(colorScheme);
    final colors =
    avatarOptions[_selectedAvatar]['bg'] as List<Color>;

    return Column(
      children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showAvatarPicker(colorScheme),
          child: Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(Icons.person,
                    color: colorScheme.onPrimary, size: 44),
              ),
              // Small edit badge
              Positioned(
                bottom: 2, right: 2,
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface,
                    border: Border.all(
                        color: colorScheme.outlineVariant, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: colorScheme.scrim.withOpacity(0.1),
                          blurRadius: 4)
                    ],
                  ),
                  child: Icon(Icons.edit,
                      size: 12, color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showAvatarPicker(colorScheme),
          child: Text('Change Avatar',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary)),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── Section card wrapper ──────────────────────────────────────────────────
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: colorScheme.scrim.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ── Personal Details ──────────────────────────────────────────────────────
  Widget _buildPersonalDetails(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildField(
            label: 'Full Name',
            controller: _nameController,
            hint: 'Enter your full name',
            colorScheme: colorScheme,
            textCapitalization: TextCapitalization.words),
        const SizedBox(height: 12),
        _buildField(
            label: 'Email Address',
            controller: _emailController,
            hint: 'your.email@example.com',
            colorScheme: colorScheme,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _buildField(
            label: 'Phone Number',
            controller: _phoneController,
            hint: '+91 XXXXX XXXXX',
            colorScheme: colorScheme,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _buildField(
            label: 'Location',
            controller: _locationController,
            colorScheme: colorScheme,
            hint: 'City, State, Country'),
      ],
    );
  }

  // ── ID Verification ───────────────────────────────────────────────────────
  Widget _buildIDVerification(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer.withOpacity(isDark ? 0.2 : 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.tertiary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: colorScheme.tertiary, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Maximum file size: 150 KB per document. '
                      'Use compressed JPG images for best results.',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: colorScheme.onTertiaryContainer,
                      height: 1.3),
                ),
              ),
            ],
          ),
        ),
        _buildUploadBox(
          label: 'Aadhaar Card',
          localFile: _newAadhaarFile,
          savedBase64: _aadhaarBase64,
          colorScheme: colorScheme,
          onTap: () => _pickDocument(true, colorScheme),
        ),
        const SizedBox(height: 12),
        _buildUploadBox(
          label: 'PAN Card',
          localFile: _newPanFile,
          savedBase64: _panBase64,
          colorScheme: colorScheme,
          onTap: () => _pickDocument(false, colorScheme),
        ),
      ],
    );
  }

  // ── KYC Details ───────────────────────────────────────────────────────────
  Widget _buildKYCDetails(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        _buildField(
          label: 'Bank Account Number',
          controller: _bankAccountController,
          hint: 'Enter account number',
          colorScheme: colorScheme,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        _buildField(
          label: 'IFSC Code',
          controller: _ifscController,
          hint: 'Enter IFSC code',
          colorScheme: colorScheme,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        _buildField(
          label: 'Bank Name',
          controller: _bankNameController,
          colorScheme: colorScheme,
          hint: 'Enter bank name',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withOpacity(isDark ? 0.2 : 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.secondary.withOpacity(0.2)),
          ),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: colorScheme.onSecondaryContainer,
                  height: 1.4),
              children: const [
                TextSpan(
                    text: 'Note: ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(
                    text:
                    'KYC verification is mandatory for participating in bidding and receiving payments.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Account Type ──────────────────────────────────────────────────────────
  Widget _buildAccountType(ColorScheme colorScheme) {
    return Row(
      children: [
        _AccountTypeButton(
          label: 'Contributor',
          icon: Icons.description_outlined,
          colorScheme: colorScheme,
          selected: _accountType == _AccountType.contributor,
          onTap: () =>
              setState(() => _accountType = _AccountType.contributor),
        ),
        const SizedBox(width: 10),
        _AccountTypeButton(
          label: 'Investor',
          icon: Icons.work_outline,
          colorScheme: colorScheme,
          selected: _accountType == _AccountType.investor,
          onTap: () =>
              setState(() => _accountType = _AccountType.investor),
        ),
        const SizedBox(width: 10),
        _AccountTypeButton(
          label: 'Both',
          icon: Icons.person_outline,
          colorScheme: colorScheme,
          selected: _accountType == _AccountType.both,
          onTap: () => setState(() => _accountType = _AccountType.both),
        ),
      ],
    );
  }

  // ── Interested Domains ────────────────────────────────────────────────────
  Widget _buildDomainsCard(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: colorScheme.scrim.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interested Domains',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('Select domains you\'re interested in',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _domains.map((domain) {
              final isSelected = _selectedDomains.contains(domain);
              return GestureDetector(
                onTap: () => setState(() => isSelected
                    ? _selectedDomains.remove(domain)
                    : _selectedDomains.add(domain)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                        : null,
                    color:
                    isSelected ? null : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(domain,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Save button ───────────────────────────────────────────────────────────
  Widget _buildSaveButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: TextButton(
          onPressed: _saving ? null : () => _saveChanges(colorScheme),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _saving
              ? SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2.0, color: colorScheme.onPrimary))
              : Text('Save Changes',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  // ── Generic labelled text field ───────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required ColorScheme colorScheme,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Upload box ────────────────────────────────────────────────────────────
  Widget _buildUploadBox({
    required String label,
    required File? localFile,
    required String? savedBase64,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    ImageProvider? imageProvider;
    bool isUnsaved = false;

    if (localFile != null) {
      imageProvider = FileImage(localFile);
      isUnsaved = true;
    } else {
      final mem = _base64ToImage(savedBase64);
      if (mem != null) imageProvider = mem;
    }

    Widget content;

    if (imageProvider != null) {
      content = Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image(
              image: imageProvider,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant, size: 28),
                ),
              ),
            ),
          ),
          // Edit icon
          Positioned(
            top: 6, right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: colorScheme.scrim.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.edit,
                  color: colorScheme.onPrimary, size: 12),
            ),
          ),
          // Status badge
          Positioned(
            bottom: 6, left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isUnsaved
                    ? colorScheme.error.withOpacity(0.9)
                    : const Color(0xFF16A34A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUnsaved ? Icons.upload : Icons.check,
                    color: colorScheme.onPrimary, size: 10,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isUnsaved ? 'Unsaved' : 'Saved',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.upload_outlined,
                size: 28, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text('Upload $label',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text('JPG / PNG  •  Max 150 KB',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            decoration: BoxDecoration(
              color: imageProvider != null
                  ? colorScheme.primary.withOpacity(0.04)
                  : colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: imageProvider != null
                    ? colorScheme.primary.withOpacity(0.4)
                    : colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: content,
          ),
        ),
      ],
    );
  }
}

// ─── Account Type Button ──────────────────────────────────────────────────────
class _AccountTypeButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         selected;
  final ColorScheme  colorScheme;
  final VoidCallback onTap;

  const _AccountTypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: selected ? null : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
              BoxShadow(
                  color: colorScheme.primary.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3))
            ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22,
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
