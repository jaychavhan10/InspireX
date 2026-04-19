import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'admin_login_screen.dart';
import '../utils/transitions.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
// Colors are now derived from the theme color scheme.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final List<TextEditingController> _pinControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
  List.generate(6, (_) => FocusNode());

  bool   _isLoading = false;
  String _pin       = '';

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onPinChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _pinFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _pinFocusNodes[index - 1].requestFocus();
    }
    setState(() {
      _pin = _pinControllers.map((c) => c.text).join();
    });
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _pin.length < 6) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _pin,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String message = 'Login failed';
      if (e.code == 'user-not-found')  message = 'User not found';
      if (e.code == 'wrong-password')  message = 'Incorrect PIN';
      if (e.code == 'invalid-email')   message = 'Invalid email';
      
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Dynamic PIN box width to prevent overflow
    final screenWidth = MediaQuery.of(context).size.width;
    // cardPadding(18*2=36) + scrollPadding(24*2=48) + 5gaps(10) = 94
    final pinBoxWidth =
    ((screenWidth - 94) / 6).floorToDouble().clamp(36.0, 50.0);

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
                horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildLogo(colorScheme),
                const SizedBox(height: 40),
                _buildCard(pinBoxWidth, colorScheme),
                const SizedBox(height: 20),
                // ── Admin Login link ─────────────────────────────────
                GestureDetector(
                  onTap: () => navigateSmoothly(
                    context,
                    const AdminLoginScreen(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings_outlined,
                          size: 15,
                          color: colorScheme.onPrimary.withOpacity(0.75)),
                      const SizedBox(width: 6),
                      Text(
                        'Admin Login',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildFooter(colorScheme),
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
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary.withOpacity(0.15),
              ),
            ),
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary,
                boxShadow: [
                  BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 4),
                ],
              ),
              child: Icon(Icons.lightbulb_outline_rounded,
                  size: 44, color: colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('InspireX',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimary,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text('Marketplace for Ideas',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: colorScheme.onPrimary.withOpacity(0.85),
                letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildCard(double pinBoxWidth, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.97),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: colorScheme.scrim.withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email or Mobile Number',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Enter your email or phone',
              hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: colorScheme.onSurfaceVariant),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: colorScheme.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Text('6-Digit PIN',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) => Row(
              children: [
                _buildPinBox(i, pinBoxWidth, colorScheme),
                if (i != 5) const SizedBox(width: 2),
              ],
            )),
          ),

          const SizedBox(height: 28),

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
                onPressed: _isLoading ? null : _handleLogin,
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
                    : Text('Log In',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Center(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: colorScheme.onSurfaceVariant),
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => navigateSmoothly(
                        context,
                        const SignupScreen(),
                      ),
                      child: Text('Create one',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary)),
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

  Widget _buildPinBox(int index, double width, ColorScheme colorScheme) {
    return SizedBox(
      width: width,
      height: 50,
      child: TextField(
        controller: _pinControllers[index],
        focusNode: _pinFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          contentPadding: EdgeInsets.zero,
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
            borderSide:
            BorderSide(color: colorScheme.primary, width: 1.8),
          ),
        ),
        onChanged: (v) => _onPinChanged(v, index),
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    return Text(
      'Secure login • Your ideas are protected',
      style: GoogleFonts.plusJakartaSans(
          fontSize: 12, color: colorScheme.onPrimary.withOpacity(0.65)),
      textAlign: TextAlign.center,
    );
  }
}
