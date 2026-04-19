import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_home_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading      = false;
  bool _obscurePass    = true;
  String _emailError   = '';
  String _passwordError = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    setState(() {
      _emailError    = '';
      _passwordError = '';
    });

    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Query Firestore admins collection
      final query = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _isLoading   = false;
          _emailError  = 'No admin found with this email.';
        });
        return;
      }

      final adminData = query.docs.first.data();
      final storedPassword = adminData['password'] as String? ?? '';

      if (storedPassword != password) {
        setState(() {
          _isLoading     = false;
          _passwordError = 'Incorrect password.';
        });
        return;
      }

      final adminName = adminData['name'] as String? ?? 'Admin';

      setState(() => _isLoading = false);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminHomeScreen(adminName: adminName),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      final errorColor = Theme.of(context).colorScheme.error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Login failed. Please try again.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary, colorScheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 24),
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.onPrimary.withOpacity(0.2),
                      ),
                      child: Icon(Icons.arrow_back,
                          color: colorScheme.onPrimary, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Logo
                _buildLogo(colorScheme),
                const SizedBox(height: 36),

                // Card
                _buildCard(colorScheme, isDark),
                const SizedBox(height: 24),

                Text(
                  'Admin access only • Authorised personnel',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: colorScheme.onPrimary.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme colorScheme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary.withOpacity(0.15),
              ),
            ),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 28,
                      spreadRadius: 4),
                ],
              ),
              child: Icon(Icons.admin_panel_settings_outlined,
                  size: 38, color: colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('InspireX Admin',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimary,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text('Secure Admin Portal',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onPrimary.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : colorScheme.surface.withOpacity(0.97),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: colorScheme.scrim.withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined,
                    color: colorScheme.primary, size: 14),
                const SizedBox(width: 5),
                Text('Admin Login',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Email field
          _fieldLabel('Admin Email', colorScheme),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailController,
            hint: 'admin@inspirex.com',
            keyboardType: TextInputType.emailAddress,
            error: _emailError,
            colorScheme: colorScheme,
          ),
          if (_emailError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_emailError,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: colorScheme.error)),
            ),
          const SizedBox(height: 16),

          // Password field
          _fieldLabel('Password', colorScheme),
          const SizedBox(height: 6),
          _buildPasswordField(colorScheme),
          if (_passwordError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_passwordError,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: colorScheme.error)),
            ),
          const SizedBox(height: 28),

          // Login button
          SizedBox(
            width: double.infinity,
            height: 50,
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
                      color: colorScheme.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: TextButton(
                onPressed: _isLoading ? null : _handleAdminLogin,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: colorScheme.onPrimary, strokeWidth: 2))
                    : Text('Login as Admin',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, ColorScheme colorScheme) => Text(text,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String error = '',
    required ColorScheme colorScheme,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: error.isNotEmpty
                  ? colorScheme.error
                  : colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: error.isNotEmpty
                  ? colorScheme.error
                  : colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField(ColorScheme colorScheme) {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePass,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Enter your password',
        hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        suffixIcon: GestureDetector(
          onTap: () =>
              setState(() => _obscurePass = !_obscurePass),
          child: Icon(
            _obscurePass
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: _passwordError.isNotEmpty
                  ? colorScheme.error
                  : colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: _passwordError.isNotEmpty
                  ? colorScheme.error
                  : colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
