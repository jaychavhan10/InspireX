import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _gradientStart = Color(0xFF7C3AED);
const _gradientMid   = Color(0xFF8B5CF6);
const _gradientEnd   = Color(0xFF3B82F6);

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

  bool _isLoading = false;
  String _pin = '';

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _pinControllers) c.dispose();
    for (final f in _pinFocusNodes) f.dispose();
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
        password: _pin, // 👈 using PIN as password
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      // ✅ Navigate to Home
      Navigator.pushReplacementNamed(context, '/home');

    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      String message = "Login failed";

      if (e.code == 'user-not-found') {
        message = "User not found";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect PIN";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> registerUser() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _pin,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created ✅")),
      );
    } catch (e) {
      print("Signup Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStart, _gradientMid, _gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildLogo(),
                const SizedBox(height: 40),
                _buildCard(),
                const SizedBox(height: 28),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo + branding ───────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Column(
      children: [
        // Glowing circle with lightbulb
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x557C3AED),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 44,
                color: _gradientStart,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'InspireX',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Marketplace for Ideas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.white.withOpacity(0.85),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ── White card ────────────────────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Email / Phone ───────────────────────────────────────────────
          Text(
            'Email or Mobile Number',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: const Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: 'Enter your email or phone',
              hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: const Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
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
                borderSide:
                const BorderSide(color: _gradientStart, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ── 6-Digit PIN ─────────────────────────────────────────────────
          Text(
            '6-Digit PIN',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              return Row(
                children: [
                  _buildPinBox(i),
                  if (i != 5) const SizedBox(width: 2), // 👈 exact gap between boxes
                ],
              );
            }),
          ),

          const SizedBox(height: 28),

          // ── Login button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
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
                    color: _gradientStart.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : Text(
                  'Log In',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ── Sign up link ────────────────────────────────────────────────
          Center(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: const Color(0xFF6B7280)),
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: Text(
                        'Create one',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _gradientStart,
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

  // ── Single PIN box ────────────────────────────────────────────────────────
  Widget _buildPinBox(int index) {
    return SizedBox(
      width: 44,
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
          color: const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: _gradientStart, width: 1.8),
          ),
        ),
        onChanged: (v) => _onPinChanged(v, index),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Text(
      'Secure login • Your ideas are protected',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: Colors.white.withOpacity(0.65),
      ),
      textAlign: TextAlign.center,
    );
  }
}
