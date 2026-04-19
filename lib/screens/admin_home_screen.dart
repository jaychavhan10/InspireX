import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_verify_profiles_screen.dart';
import 'admin_verify_ideas_screen.dart';
import '../utils/transitions.dart';

class AdminHomeScreen extends StatelessWidget {
  final String adminName;
  const AdminHomeScreen({super.key, required this.adminName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          _buildAppBar(context, colorScheme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: colorScheme.primary.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onPrimary.withOpacity(0.15),
                          ),
                          child: Icon(
                              Icons.admin_panel_settings_outlined,
                              color: colorScheme.onPrimary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back,',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: colorScheme.onPrimary
                                          .withOpacity(0.8))),
                              Text(adminName,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Admin Actions',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('Review and manage platform content',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),

                  // Verify Profiles card
                  _AdminActionCard(
                    icon: Icons.people_outline,
                    title: 'Verify Profiles',
                    subtitle:
                    'Review submitted user profiles, check ID & KYC documents, approve or reject accounts.',
                    gradientColors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    onTap: () => navigateSmoothly(
                      context,
                      const AdminVerifyProfilesScreen(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Verify Ideas card
                  _AdminActionCard(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Verify Ideas',
                    subtitle:
                    'Review submitted idea submissions, check patent documents, approve or reject ideas for the marketplace.',
                    gradientColors: [
                      colorScheme.tertiary,
                      colorScheme.secondary,
                    ],
                    onTap: () => navigateSmoothly(
                      context,
                      const AdminVerifyIdeasScreen(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Stats row
                  Row(
                    children: [
                      _StatCard(
                          label: 'Pending Profiles',
                          icon: Icons.hourglass_empty_outlined,
                          color: const Color(0xFFFBBF24)),
                      const SizedBox(width: 12),
                      _StatCard(
                          label: 'Pending Ideas',
                          icon: Icons.pending_outlined,
                          color: colorScheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: colorScheme.surface,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Text('InspireX',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                        letterSpacing: -0.5)),
              ),
            ),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Theme(
                    data: Theme.of(context),
                    child: AlertDialog(
                      backgroundColor: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      title: Text('Logout',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface)),
                      content: Text('Are you sure you want to logout?',
                          style:
                          GoogleFonts.plusJakartaSans(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/login', (_) => false);
                          },
                          child: Text('Logout',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Icon(Icons.logout,
                  color: colorScheme.error, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────────────────────
class _AdminActionCard extends StatelessWidget {
  final IconData        icon;
  final String          title;
  final String          subtitle;
  final List<Color>     gradientColors;
  final VoidCallback    onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: colorScheme.scrim.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // Coloured left accent
            Container(
              width: 5,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.onPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card (live Firestore count) ────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.color,
  });

  Stream<int> _countStream() {
    if (label.contains('Profile')) {
      // Count users where profileStatus is null OR 'pending'
      return FirebaseFirestore.instance
          .collection('users')
          .snapshots()
          .map((s) => s.docs.where((d) {
        final status = d.data()['profileStatus'] as String?;
        return status == null || status == 'pending';
      }).length);
    } else {
      return FirebaseFirestore.instance
          .collectionGroup('ideas')
          .snapshots()
          .map((s) => s.docs.where((d) {
        final status = d.data()['status'] as String?;
        return status == null ||
            status == 'pending' ||
            status == 'pending_review';
      }).length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: colorScheme.scrim.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: StreamBuilder<int>(
          stream: _countStream(),
          builder: (_, snap) {
            final count = snap.data ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 8),
                Text('$count',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface)),
                const SizedBox(height: 1),
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant)),
              ],
            );
          },
        ),
      ),
    );
  }
}
