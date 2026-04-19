import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/transitions.dart';

// ─── AdminVerifyProfilesScreen ────────────────────────────────────────────────
class AdminVerifyProfilesScreen extends StatefulWidget {
  const AdminVerifyProfilesScreen({super.key});

  @override
  State<AdminVerifyProfilesScreen> createState() =>
      _AdminVerifyProfilesScreenState();
}

class _AdminVerifyProfilesScreenState
    extends State<AdminVerifyProfilesScreen> {
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // No where(), no orderBy() → zero index requirements
  Stream<QuerySnapshot<Map<String, dynamic>>> get _stream =>
      FirebaseFirestore.instance.collection('users').snapshots();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          _buildAppBar(context, colorScheme),
          _buildSearchBar(context, colorScheme),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: colorScheme.primary));
                }

                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error: ${snap.error}',
                        style: GoogleFonts.plusJakartaSans(
                            color: colorScheme.onSurfaceVariant, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                var docs = snap.data?.docs ?? [];

                // Sort client-side: newest first
                docs.sort((a, b) {
                  final aRaw = a.data()['createdAt'];
                  final bRaw = b.data()['createdAt'];
                  final aTime = aRaw is Timestamp
                      ? aRaw.millisecondsSinceEpoch
                      : (aRaw as int? ?? 0);
                  final bTime = bRaw is Timestamp
                      ? bRaw.millisecondsSinceEpoch
                      : (bRaw as int? ?? 0);
                  return bTime.compareTo(aTime);
                });

                // Search filter (client-side)
                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final name =
                    (d.data()['fullName'] as String? ?? '').toLowerCase();
                    return name.contains(_search.toLowerCase());
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48, color: colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text('No profiles found.',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ProfileCard(doc: docs[i]),
                );
              },
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back,
                  color: colorScheme.onSurface, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Center(
                child: Text('Verify Profiles',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5)),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _search = v),
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14, color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search by name...',
          hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: colorScheme.onSurfaceVariant),
          prefixIcon:
          Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 20),
          suffixIcon: _search.isNotEmpty
              ? GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _search = '');
              },
              child: Icon(Icons.close,
                  color: colorScheme.onSurfaceVariant, size: 18))
              : null,
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _ProfileCard({required this.doc});

  Color _statusColor(BuildContext context, String? status) {
    switch (status) {
      case 'approved': return const Color(0xFF16A34A);
      case 'rejected': return Theme.of(context).colorScheme.error;
      case 'on_hold':  return const Color(0xFFFBBF24);
      default:         return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'approved': return 'Verified';
      case 'rejected': return 'Rejected';
      case 'on_hold':  return 'On Hold';
      default:         return 'Pending';
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      case 'on_hold':  return Icons.pause_circle_outline;
      default:         return Icons.hourglass_empty_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final data   = doc.data();
    final name   = data['fullName']      as String? ?? 'Unknown';
    final email  = data['email']         as String? ?? '';
    final role   = data['role']          as String? ?? 'contributor';
    final mobile = data['mobile']        as String? ?? '';
    final status = data['profileStatus'] as String?;

    return GestureDetector(
      onTap: () => navigateSmoothly(context, AdminProfileDetailScreen(docId: doc.id, data: data)),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: colorScheme.scrim.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimary),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface)),
                  const SizedBox(height: 1),
                  Text(email,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chipTag(context, _roleLabel(role), colorScheme.primary),
                      const SizedBox(width: 6),
                      if (mobile.isNotEmpty)
                        Text(mobile,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),

            // Status badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(_statusIcon(status),
                    color: _statusColor(context, status), size: 16),
                const SizedBox(height: 2),
                Text(_statusLabel(status),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(context, status))),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right,
                    color: colorScheme.outlineVariant, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'investor': return 'Investor';
      case 'both':     return 'Both';
      default:         return 'Contributor';
    }
  }

  Widget _chipTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ─── Profile Detail Screen ────────────────────────────────────────────────────
class AdminProfileDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const AdminProfileDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<AdminProfileDetailScreen> createState() =>
      _AdminProfileDetailScreenState();
}

class _AdminProfileDetailScreenState
    extends State<AdminProfileDetailScreen> {
  final _reasonController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    final colorScheme = Theme.of(context).colorScheme;
    setState(() => _saving = true);
    try {
      final update = <String, dynamic>{
        'profileStatus': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      };
      if (_reasonController.text.trim().isNotEmpty) {
        update['adminReason'] = _reasonController.text.trim();
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.docId)
          .update(update);

      setState(() => _saving = false);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile status updated to $status',
            style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update: $e',
            style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final d = widget.data;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: colorScheme.onSurfaceVariant, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Profile Details',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface)),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _infoCard(context, colorScheme, 'Personal Details', [
                  _row(context, colorScheme, 'Full Name', d['fullName']),
                  _row(context, colorScheme, 'Email', d['email']),
                  _row(context, colorScheme, 'Mobile', d['mobile']),
                  _row(context, colorScheme, 'Location', d['location']),
                  _row(context, colorScheme, 'Role', d['role']),
                ]),
                const SizedBox(height: 14),

                _infoCard(context, colorScheme, 'KYC Details', [
                  _row(context, colorScheme, 'Bank Account', d['bankAccount']),
                  _row(context, colorScheme, 'IFSC Code', d['ifsc']),
                  _row(context, colorScheme, 'Bank Name', d['bankName']),
                ]),
                const SizedBox(height: 14),

                _docImageCard(context, colorScheme, 'Aadhaar Card', d['aadhaarBase64']),
                const SizedBox(height: 14),
                _docImageCard(context, colorScheme, 'PAN Card', d['panBase64']),
                const SizedBox(height: 14),

                if ((d['domains'] as List?)?.isNotEmpty == true)
                  _infoCard(context, colorScheme, 'Interested Domains', [
                    _domainsRow(
                        context, colorScheme, List<String>.from(d['domains'] ?? [])),
                  ]),
                const SizedBox(height: 14),

                // Reason input
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: colorScheme.scrim.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reason / Note (optional)',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reasonController,
                        maxLines: 3,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText:
                          'Add a reason for approval/rejection...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                            BorderSide(color: colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                            BorderSide(color: colorScheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: colorScheme.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                if (_saving)
                  Center(
                      child: CircularProgressIndicator(color: colorScheme.primary))
                else
                  Column(
                    children: [
                      _actionButton(
                        label: 'Approve',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF16A34A),
                        onTap: () => _updateStatus('approved'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _actionButtonSmall(
                              label: 'On Hold',
                              icon: Icons.pause_circle_outline,
                              color: const Color(0xFFFBBF24),
                              onTap: () => _updateStatus('on_hold'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _actionButtonSmall(
                              label: 'Reject',
                              icon: Icons.cancel_outlined,
                              color: colorScheme.error,
                              onTap: () => _updateStatus('rejected'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, ColorScheme colorScheme, String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: colorScheme.scrim.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ColorScheme colorScheme, String label, dynamic value) {
    if (value == null || (value is String && value.isEmpty)) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text('$value',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _domainsRow(BuildContext context, ColorScheme colorScheme, List<String> domains) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: domains
          .map((d) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(d,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary)),
      ))
          .toList(),
    );
  }

  Widget _docImageCard(BuildContext context, ColorScheme colorScheme, String label, String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: colorScheme.scrim.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.image_not_supported_outlined,
                color: colorScheme.outlineVariant, size: 24),
            const SizedBox(width: 10),
            Text('$label not uploaded',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    try {
      final bytes = base64Decode(base64Str.replaceAll(RegExp(r'\s'), ''));
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: colorScheme.scrim.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                bytes,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox();
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _actionButtonSmall({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
