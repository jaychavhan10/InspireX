import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'idea_bidding_screen.dart';
import 'notifications_screen.dart';
import '../utils/transitions.dart';

// ─── Feed publishing helper ───────────────────────────────────────────────────
//
// Call this when admin sets status → 'approved'.
// It writes the idea into the shared `approved_ideas` collection so that
// every user (including the submitter) sees it in their Home & Search feed.
//
// Pass [remove: true] when an idea is un-approved (rejected / on_hold)
// to remove it from the public feed.
Future<void> publishToFeed({
  required String docId,
  required Map<String, dynamic> ideaData,
  bool remove = false,
}) async {
  final feedRef = FirebaseFirestore.instance
      .collection('approved_ideas')
      .doc(docId); // use same docId so it's idempotent

  if (remove) {
    await feedRef.delete();
  } else {
    await feedRef.set({
      ...ideaData,
      'approvedAt': FieldValue.serverTimestamp(),
      'isSeeded': false,
    }, SetOptions(merge: true));
  }
}

// ─── MyIdeasScreen ────────────────────────────────────────────────────────────
class MyIdeasScreen extends StatefulWidget {
  const MyIdeasScreen({super.key});

  @override
  State<MyIdeasScreen> createState() => _MyIdeasScreenState();
}

class _MyIdeasScreenState extends State<MyIdeasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  final _tabs = const ['All', 'Approved', 'Pending', 'Rejected', 'On Hold'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _ideasStream {
    if (_uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('ideas')
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filter(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      int tabIndex,
      ) {
    docs.sort((a, b) {
      final aT = a.data()['createdAt'] as int? ?? 0;
      final bT = b.data()['createdAt'] as int? ?? 0;
      return bT.compareTo(aT);
    });

    switch (tabIndex) {
      case 1:
        return docs.where((d) => d.data()['status'] == 'approved').toList();
      case 2:
        return docs
            .where((d) =>
        d.data()['status'] == 'pending_review' ||
            d.data()['status'] == null)
            .toList();
      case 3:
        return docs.where((d) => d.data()['status'] == 'rejected').toList();
      case 4:
        return docs.where((d) => d.data()['status'] == 'on_hold').toList();
      default:
        return docs;
    }
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
          _buildAppBar(colorScheme),
          _buildTabBar(colorScheme),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _ideasStream,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  );
                }
                if (snap.hasError) {
                  return _ErrorView(message: '${snap.error}', colorScheme: colorScheme);
                }

                final allDocs = snap.data?.docs ?? [];

                return TabBarView(
                  controller: _tabController,
                  children: List.generate(_tabs.length, (i) {
                    final filtered = _filter(List.from(allDocs), i);
                    if (filtered.isEmpty) {
                      return _EmptyState(tabLabel: _tabs[i], colorScheme: colorScheme);
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 14),
                      itemBuilder: (_, idx) =>
                          _IdeaCard(doc: filtered[idx]),
                    );
                  }),
                );
              },
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Ideas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Track and manage your submitted ideas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _NotificationBell(uid: _uid, colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorWeight: 2.5,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}

// ─── Idea Card ────────────────────────────────────────────────────────────────
class _IdeaCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _IdeaCard({required this.doc});

  // ── Status helpers ────────────────────────────────────────────────────────
  String _statusLabel(String? s) {
    switch (s) {
      case 'approved':      return 'Approved';
      case 'rejected':      return 'Rejected';
      case 'on_hold':       return 'On Hold';
      case 'pending_review':
      default:              return 'Under Review';
    }
  }

  Color _statusColor(String? s, ColorScheme colorScheme) {
    switch (s) {
      case 'approved': return const Color(0xFF16A34A);
      case 'rejected': return colorScheme.error;
      case 'on_hold':  return colorScheme.tertiary;
      default:         return colorScheme.onSurfaceVariant;
    }
  }

  IconData _statusIcon(String? s) {
    switch (s) {
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      case 'on_hold':  return Icons.pause_circle_outline;
      default:         return Icons.hourglass_top_outlined;
    }
  }

  Color _statusBg(String? s, ColorScheme colorScheme, bool isDark) {
    switch (s) {
      case 'approved': return const Color(0xFF16A34A).withOpacity(isDark ? 0.15 : 0.1);
      case 'rejected': return colorScheme.error.withOpacity(isDark ? 0.15 : 0.1);
      case 'on_hold':  return colorScheme.tertiary.withOpacity(isDark ? 0.15 : 0.1);
      default:         return colorScheme.surfaceContainerHighest;
    }
  }

  // ── Publish / unpublish from shared feed ──────────────────────────────────
  Future<void> _syncFeed(String docId, Map<String, dynamic> data) async {
    final status = data['status'] as String?;
    if (status == 'approved') {
      await publishToFeed(docId: docId, ideaData: data);
    } else {
      // If previously approved but now rejected/on_hold, remove from feed
      await publishToFeed(docId: docId, ideaData: data, remove: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark      = theme.brightness == Brightness.dark;

    final d           = doc.data();
    final title       = d['title']       as String? ?? 'Untitled';
    final category    = d['category']    as String? ?? '';
    final patented    = d['isPatented']  as bool?   ?? false;
    final status      = d['status']      as String?;
    final basePrice   = d['basePrice']   as int?    ?? 0;
    final likes       = d['likes']       as int?    ?? 0;
    final interested  = d['interested']  as int?    ?? 0;
    final adminReason = d['adminReason'] as String?;
    final biddingDate = d['biddingDate'] as String?;
    final biddingTime = d['biddingTime'] as String?;

    // ── Auto-publish when card is built and status is approved ────────────
    if (status == 'approved') {
      _syncFeed(doc.id, d);
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.scrim.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _statusBg(status, colorScheme, isDark),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(status),
                    size: 16, color: _statusColor(status, colorScheme)),
                const SizedBox(width: 6),
                Text(
                  _statusLabel(status),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status, colorScheme),
                  ),
                ),
                const Spacer(),
                // "Live on Feed" badge for approved ideas
                if (status == 'approved')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF16A34A).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live on Feed',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (status == 'pending_review' || status == null)
                  _AnimatedDot(colorScheme: colorScheme),
              ],
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Tags ─────────────────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (category.isNotEmpty)
                      _Tag(
                        label: category,
                        bgColor: colorScheme.primaryContainer.withOpacity(isDark ? 0.3 : 1.0),
                        textColor: isDark ? colorScheme.primary : colorScheme.onPrimaryContainer,
                      ),
                    _Tag(
                      icon: patented
                          ? Icons.verified_outlined
                          : Icons.block_outlined,
                      label: patented ? 'Patented' : 'Not Patented',
                      bgColor: patented
                          ? const Color(0xFFDCFCE7).withOpacity(isDark ? 0.2 : 1.0)
                          : colorScheme.surfaceContainerHighest,
                      textColor: patented
                          ? const Color(0xFF16A34A)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Stats row ─────────────────────────────────────────────
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.thumb_up_alt_outlined,
                      value: '$likes',
                      label: 'Likes',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.people_outline,
                      value: '$interested',
                      label: 'Interested',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.attach_money,
                      value: '\$$basePrice',
                      label: 'Base Price',
                      colorScheme: colorScheme,
                    ),
                  ],
                ),

                // ── Bidding schedule ──────────────────────────────────────
                if (status == 'approved' &&
                    (biddingDate != null || biddingTime != null)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withOpacity(isDark ? 0.2 : 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border:
                      Border.all(color: colorScheme.tertiary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: colorScheme.tertiary),
                        const SizedBox(width: 6),
                        Text(
                          [biddingDate, biddingTime]
                              .where((e) => e != null && e.isNotEmpty)
                              .join('  •  '),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Admin reason (rejected / on_hold) ─────────────────────
                if (adminReason != null &&
                    adminReason.isNotEmpty &&
                    (status == 'rejected' || status == 'on_hold')) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: status == 'rejected'
                          ? colorScheme.errorContainer.withOpacity(isDark ? 0.3 : 0.6)
                          : colorScheme.tertiaryContainer.withOpacity(isDark ? 0.3 : 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 15,
                          color: status == 'rejected'
                              ? colorScheme.error
                              : colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Note',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: status == 'rejected'
                                      ? colorScheme.onErrorContainer
                                      : colorScheme.onTertiaryContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                adminReason,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: status == 'rejected'
                                      ? colorScheme.onErrorContainer
                                      : colorScheme.onTertiaryContainer,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── CTA (approved ideas only) ─────────────────────────────
                if (status == 'approved') ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
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
                        onPressed: () => navigateSmoothly(context, IdeaBiddingScreen(ideaTitle: title)),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'View Bidding',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated "reviewing" dot ─────────────────────────────────────────────────
class _AnimatedDot extends StatefulWidget {
  final ColorScheme colorScheme;
  const _AnimatedDot({required this.colorScheme});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final ColorScheme colorScheme;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.primary),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tag ──────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color bgColor;
  final Color textColor;
  const _Tag({
    this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification Bell ────────────────────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  final String? uid;
  final ColorScheme colorScheme;
  const _NotificationBell({required this.uid, required this.colorScheme});

  Stream<int> get _unreadCount {
    if (uid == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateSmoothly(context, NotificationsScreen(uid: uid)),
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: StreamBuilder<int>(
          stream: _unreadCount,
          builder: (_, snap) {
            final count = snap.data ?? 0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined,
                    color: colorScheme.onSurface, size: 26),
                if (count > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: TextStyle(
                          color: colorScheme.onPrimary, // High-contrast for count badge
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}


// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String tabLabel;
  final ColorScheme colorScheme;
  const _EmptyState({required this.tabLabel, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline,
              size: 52, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            tabLabel == 'All'
                ? "You haven't submitted any ideas yet"
                : 'No $tabLabel ideas',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tabLabel == 'All'
                ? 'Tap the + button on home to get started'
                : 'Check back later',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final ColorScheme colorScheme;
  const _ErrorView({required this.message, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Error: $message',
          style: GoogleFonts.plusJakartaSans(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
