import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatelessWidget {
  final String? uid;
  const NotificationsScreen({super.key, required this.uid});

  Stream<QuerySnapshot<Map<String, dynamic>>> get _stream {
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _markRead(String uid, String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(docId)
        .update({'read': true});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerLow,
      body: Column(
        children: [
          SafeArea(
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
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none_outlined,
                            size: 48, color: colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final d    = docs[i].data();
                    final read = d['read'] as bool? ?? false;
                    final type = d['type'] as String? ?? '';

                    Color dotColor;
                    IconData notifIcon;
                    if (type == 'approved') {
                      dotColor  = const Color(0xFF16A34A);
                      notifIcon = Icons.check_circle_outline;
                    } else if (type == 'rejected') {
                      dotColor  = colorScheme.error;
                      notifIcon = Icons.cancel_outlined;
                    } else if (type == 'on_hold') {
                      dotColor  = colorScheme.tertiary;
                      notifIcon = Icons.pause_circle_outline;
                    } else {
                      dotColor  = colorScheme.primary;
                      notifIcon = Icons.notifications_outlined;
                    }

                    return GestureDetector(
                      onTap: () {
                        if (!read && uid != null) {
                          _markRead(uid!, docs[i].id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: read
                              ? colorScheme.surface
                              : colorScheme.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: read
                                ? colorScheme.outlineVariant
                                : colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: dotColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(notifIcon,
                                  size: 18, color: dotColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['title'] as String? ?? '',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    d['body'] as String? ?? '',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!read)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dotColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
