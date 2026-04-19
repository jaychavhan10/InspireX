import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/transitions.dart';

// ─── AdminVerifyIdeasScreen ───────────────────────────────────────────────────
class AdminVerifyIdeasScreen extends StatefulWidget {
  const AdminVerifyIdeasScreen({super.key});

  @override
  State<AdminVerifyIdeasScreen> createState() =>
      _AdminVerifyIdeasScreenState();
}

class _AdminVerifyIdeasScreenState extends State<AdminVerifyIdeasScreen> {
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _stream =>
      FirebaseFirestore.instance.collectionGroup('ideas').snapshots();

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

                docs.sort((a, b) {
                  final aTime = a.data()['createdAt'] as int? ?? 0;
                  final bTime = b.data()['createdAt'] as int? ?? 0;
                  return bTime.compareTo(aTime);
                });

                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final title =
                    (d.data()['title'] as String? ?? '').toLowerCase();
                    return title.contains(_search.toLowerCase());
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 44, color: colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text('No ideas found.',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _IdeaCard(doc: docs[i]),
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
                  color: colorScheme.onSurface, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Center(
                child: Text('Verify Ideas',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface)),
              ),
            ),
            const SizedBox(width: 44),
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
            fontSize: 13, color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search by idea title...',
          hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: colorScheme.onSurfaceVariant),
          prefixIcon:
          Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 18),
          suffixIcon: _search.isNotEmpty
              ? GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _search = '');
              },
              child: Icon(Icons.close,
                  color: colorScheme.onSurfaceVariant, size: 16))
              : null,
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        ),
      ),
    );
  }
}

// ─── Idea Card ────────────────────────────────────────────────────────────────
class _IdeaCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _IdeaCard({required this.doc});

  Color _statusColor(BuildContext context, String? s) {
    switch (s) {
      case 'approved': return const Color(0xFF16A34A);
      case 'rejected': return Theme.of(context).colorScheme.error;
      case 'on_hold':  return const Color(0xFFFBBF24);
      default:         return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'on_hold':  return 'On Hold';
      default:         return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme  = Theme.of(context).colorScheme;
    final data         = doc.data();
    final title        = data['title']       as String? ?? 'Untitled';
    final category     = data['category']    as String? ?? '';
    final patented     = data['isPatented']  as bool?   ?? false;
    final price        = data['basePrice']   as int?    ?? 0;
    final status       = data['status']      as String?;
    final hasPatentImg =
        (data['patentImageBase64'] as String?)?.isNotEmpty == true;

    return GestureDetector(
      onTap: () => navigateSmoothly(context, AdminIdeaDetailScreen(docId: doc.id, data: data)),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: colorScheme.scrim.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(context, status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_statusLabel(status),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(context, status))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (category.isNotEmpty) ...[
                  _tag(context, category, colorScheme.primary),
                  const SizedBox(width: 6),
                ],
                _tag(
                  context,
                  patented ? 'Patented' : 'Not Patented',
                  patented
                      ? const Color(0xFF16A34A)
                      : colorScheme.onSurfaceVariant,
                ),
                if (hasPatentImg) ...[
                  const SizedBox(width: 6),
                  _tag(context, '📄 Patent Doc', colorScheme.secondary),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money,
                    size: 13, color: colorScheme.onSurfaceVariant),
                Text('Base: \$$price',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: colorScheme.onSurfaceVariant)),
                const Spacer(),
                Icon(Icons.chevron_right,
                    color: colorScheme.outlineVariant, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );
}

// ─── Idea Detail Screen ───────────────────────────────────────────────────────
class AdminIdeaDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const AdminIdeaDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<AdminIdeaDetailScreen> createState() =>
      _AdminIdeaDetailScreenState();
}

class _AdminIdeaDetailScreenState extends State<AdminIdeaDetailScreen> {
  final _reasonController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ── Notification content per status ──────────────────────────────────────
  Map<String, String> _notifContent(String status, String ideaTitle) {
    final reason = _reasonController.text.trim();
    switch (status) {
      case 'approved':
        return {
          'title': '🎉 Congratulations! Idea Approved',
          'body':
          'Your idea "$ideaTitle" has been approved and is now visible to '
              'other users. Track your idea\'s progress in My Ideas!',
        };
      case 'rejected':
        return {
          'title': '❌ Idea Not Approved',
          'body': reason.isNotEmpty
              ? 'Your idea "$ideaTitle" was rejected. Admin note: $reason'
              : 'Your idea "$ideaTitle" was not approved at this time. '
              'Please review and resubmit.',
        };
      case 'on_hold':
        return {
          'title': '⏸️ Idea Placed On Hold',
          'body': reason.isNotEmpty
              ? 'Your idea "$ideaTitle" is on hold. Admin note: $reason'
              : 'Your idea "$ideaTitle" has been placed on hold pending '
              'further review.',
        };
      default:
        return {'title': 'Idea Update', 'body': 'Your idea status changed.'};
    }
  }

  Future<void> _updateStatus(String status) async {
    final colorScheme = Theme.of(context).colorScheme;
    setState(() => _saving = true);
    try {
      final uid       = widget.data['uid']   as String?;
      final ideaTitle = widget.data['title'] as String? ?? 'Your Idea';
      final reason    = _reasonController.text.trim();

      final update = <String, dynamic>{
        'status':     status,
        'reviewedAt': FieldValue.serverTimestamp(),
      };
      if (reason.isNotEmpty) update['adminReason'] = reason;

      // ── 1. Update the idea doc ────────────────────────────────────────────
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('ideas')
            .doc(widget.docId)
            .update(update);

        // ── 2. Write in-app notification ──────────────────────────────────
        final notifContent = _notifContent(status, ideaTitle);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .add({
          'type':      status,
          'title':     notifContent['title'],
          'body':      notifContent['body'],
          'ideaTitle': ideaTitle,
          'ideaId':    widget.docId,
          'read':      false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // ── 3. Write to top-level approved_ideas (for home-feed) ──────────
        //      Only approved ideas are shown on the public home feed.
        if (status == 'approved') {
          await FirebaseFirestore.instance
              .collection('approved_ideas')
              .doc(widget.docId)
              .set({
            ...widget.data,
            'status':       'approved',
            'uid':          uid,
            'approvedAt':   FieldValue.serverTimestamp(),
            // Reset engagement counters on the public copy
            'likes':        widget.data['likes']      ?? 0,
            'interested':   widget.data['interested'] ?? 0,
            // Remove sensitive base64 patent image from public copy
            'patentImageBase64': FieldValue.delete(),
          }, SetOptions(merge: true));
        } else {
          // If previously approved and now rejected/on_hold, remove from feed
          await FirebaseFirestore.instance
              .collection('approved_ideas')
              .doc(widget.docId)
              .delete()
              .catchError((_) {}); // ignore if doesn't exist
        }
      }

      setState(() => _saving = false);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Idea status updated to $status',
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
                  horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: colorScheme.onSurfaceVariant, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Idea Details',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface)),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _infoCard(context, colorScheme, 'Idea Information', [
                  _row(context, colorScheme, 'Title', d['title']),
                  _row(context, colorScheme, 'Category', d['category']),
                  _row(context, colorScheme, 'Patented',
                      (d['isPatented'] as bool? ?? false) ? 'Yes' : 'No'),
                  _row(context, colorScheme, 'Base Price', '\$${d['basePrice'] ?? 0}'),
                  if ((d['aiSuggestedPrice'] as int?) != null)
                    _row(context, colorScheme, 'AI Suggested', '\$${d['aiSuggestedPrice']}'),
                  _row(context, colorScheme, 'Bidding Date', d['biddingDate']),
                  _row(context, colorScheme, 'Bidding Time', d['biddingTime']),
                ]),
                const SizedBox(height: 12),
                _textCard(context, colorScheme, 'Problem Statement', d['problemStatement']),
                const SizedBox(height: 12),
                _textCard(context, colorScheme, 'Detailed Solution', d['detailedSolution']),
                const SizedBox(height: 12),
                if (d['isPatented'] == true)
                  _patentImageCard(context, colorScheme, d['patentImageBase64']),
                const SizedBox(height: 12),

                // ── Reason / Note field ──────────────────────────────────
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
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reason / Note (optional)',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(
                        'This note will be sent to the user as part of their notification.',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reasonController,
                        maxLines: 3,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Add a reason for your decision...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: colorScheme.outlineVariant),
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
                const SizedBox(height: 16),

                // ── Action buttons ───────────────────────────────────────
                if (_saving)
                  Center(
                      child: CircularProgressIndicator(color: colorScheme.primary))
                else
                  Column(
                    children: [
                      _actionButton(
                        label: 'Approve Idea',
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _textCard(BuildContext context, ColorScheme colorScheme, String title, String? text) {
    if (text == null || text.isEmpty) return const SizedBox();
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
          Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(text,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _patentImageCard(BuildContext context, ColorScheme colorScheme, String? base64Str) {
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
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.image_not_supported_outlined,
                color: colorScheme.outlineVariant, size: 20),
            const SizedBox(width: 10),
            Text('Patent document not uploaded',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: colorScheme.onSurfaceVariant)),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_outlined,
                    color: colorScheme.primary, size: 14),
                const SizedBox(width: 6),
                Text('Patent Certificate',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface)),
              ],
            ),
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
            width: 100,
            child: Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text('$value',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface)),
          ),
        ],
      ),
    );
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
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700)),
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
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: color),
        label: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
