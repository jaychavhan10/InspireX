import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_screen.dart';
import 'submit_idea_screen.dart';
import 'leaderboard_screen.dart';
import 'all_bidding_screen.dart';
import 'profile_screen.dart';
import 'idea_bidding_screen.dart';
import 'idea_detail_screen.dart';
import 'my_ideas_screen.dart';
import 'notifications_screen.dart';
import '../theme_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ml_service.dart';
import '../utils/transitions.dart';

// ─── Placeholder screen ───────────────────────────────────────────────────────
class LiveBiddingScreen extends StatelessWidget {
  const LiveBiddingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Live Bidding', style: _appBarTextStyle())),
    body: const Center(
        child: Text('Live Bidding Screen – Upcoming / Ongoing / Completed')),
  );
}

TextStyle _appBarTextStyle() => GoogleFonts.plusJakartaSans(
  fontWeight: FontWeight.w600,
  fontSize: 18,
);

// ─── Constants ────────────────────────────────────────────────────────────────
// Colors are now derived from the theme color scheme.

Color _getCategoryTagBg(String cat, ColorScheme colorScheme, bool isDark) {
  final map = <String, Color>{
    'Food':          const Color(0xFFFFF3E0),
    'AI':            const Color(0xFFF3E8FF),
    'Automobile':    const Color(0xFFEFF6FF),
    'Healthcare':    const Color(0xFFFEF2F2),
    'Blockchain':    const Color(0xFFECFEFF),
    'IoT':           const Color(0xFFF0FDF4),
    'Sustainability':const Color(0xFFECFDF5),
  };
  final base = map[cat] ?? colorScheme.surfaceContainerHighest;
  if (isDark) return base.withOpacity(0.15);
  return base;
}

Color _getCategoryTagText(String cat, ColorScheme colorScheme, bool isDark) {
  final map = <String, Color>{
    'Food':          const Color(0xFFE65100),
    'AI':            const Color(0xFF6D28D9),
    'Automobile':    const Color(0xFF1D4ED8),
    'Healthcare':    const Color(0xFFDC2626),
    'Blockchain':    const Color(0xFF0E7490),
    'IoT':           const Color(0xFF15803D),
    'Sustainability':const Color(0xFF047857),
  };
  final base = map[cat] ?? colorScheme.onSurfaceVariant;
  if (isDark) return base.withOpacity(0.9);
  return base;
}

// ─── Dummy seed ideas (same as search_screen) ─────────────────────────────────
final _seedIdeas = [
  {
    'title': 'AI-Powered Meal Planning Assistant',
    'detailedSolution':
    'An intelligent system that creates personalized meal plans based on dietary restrictions, budget, and local ingredient availability.',
    'likes': 245,
    'aiRating': 4.5,
    'category': 'Food',
    'isPatented': true,
    'approvedAt': DateTime(2024, 1, 1).millisecondsSinceEpoch,
    'contributorName': 'Rahul Sharma',
    'isSeeded': true,
  },
  {
    'title': 'Blockchain-Based Supply Chain Tracker',
    'detailedSolution':
    'Real-time tracking solution for supply chain management using blockchain technology to ensure transparency and reduce fraud.',
    'likes': 189,
    'aiRating': 4.2,
    'category': 'Blockchain',
    'isPatented': false,
    'approvedAt': DateTime(2024, 1, 2).millisecondsSinceEpoch,
    'contributorName': 'Priya Patel',
    'isSeeded': true,
  },
  {
    'title': 'Smart Home Energy Optimizer',
    'detailedSolution':
    'IoT device that learns your energy consumption patterns and automatically optimizes power usage to reduce bills by up to 40%.',
    'likes': 312,
    'aiRating': 4.8,
    'category': 'IoT',
    'isPatented': true,
    'approvedAt': DateTime(2024, 1, 3).millisecondsSinceEpoch,
    'contributorName': 'Amit Kumar',
    'isSeeded': true,
  },
  {
    'title': 'Virtual Reality Therapy Platform',
    'detailedSolution':
    'VR-based mental health platform providing immersive therapy sessions for anxiety, PTSD, and phobias with licensed therapists.',
    'likes': 278,
    'aiRating': 4.6,
    'category': 'Healthcare',
    'isPatented': false,
    'approvedAt': DateTime(2024, 1, 4).millisecondsSinceEpoch,
    'contributorName': 'Neha Gupta',
    'isSeeded': true,
  },
  {
    'title': 'AI Code Review Assistant',
    'detailedSolution':
    'Automated code review tool powered by machine learning that identifies bugs, security vulnerabilities, and suggests optimizations.',
    'likes': 421,
    'aiRating': 4.9,
    'category': 'AI',
    'isPatented': true,
    'approvedAt': DateTime(2024, 1, 5).millisecondsSinceEpoch,
    'contributorName': 'Vikram Singh',
    'isSeeded': true,
  },
  {
    'title': 'Sustainable Packaging Solution',
    'detailedSolution':
    'Biodegradable packaging material made from agricultural waste that decomposes within 30 days and costs less than plastic.',
    'likes': 356,
    'aiRating': 4.7,
    'category': 'Sustainability',
    'isPatented': false,
    'approvedAt': DateTime(2024, 1, 6).millisecondsSinceEpoch,
    'contributorName': 'Ananya Roy',
    'isSeeded': true,
  },
  {
    'title': 'Smart Restaurant Inventory System',
    'detailedSolution':
    'AI-driven inventory management for restaurants that predicts demand and reduces food waste by 50%.',
    'likes': 198,
    'aiRating': 4.3,
    'category': 'Food',
    'isPatented': false,
    'approvedAt': DateTime(2024, 1, 7).millisecondsSinceEpoch,
    'contributorName': 'Suresh Nair',
    'isSeeded': true,
  },
  {
    'title': 'Autonomous Delivery Drone Network',
    'detailedSolution':
    'Urban delivery system using autonomous drones for last-mile delivery, reducing delivery times by 70%.',
    'likes': 334,
    'aiRating': 4.4,
    'category': 'Automobile',
    'isPatented': true,
    'approvedAt': DateTime(2024, 1, 8).millisecondsSinceEpoch,
    'contributorName': 'Kavya Menon',
    'isSeeded': true,
  },
];

// ─── Seed helper — runs once; skips if seed docs already exist ────────────────
Future<void> _seedApprovedIdeasIfEmpty() async {
  final col = FirebaseFirestore.instance.collection('approved_ideas');
  final existing = await col
      .where('isSeeded', isEqualTo: true)
      .limit(1)
      .get();
  if (existing.docs.isNotEmpty) return; // already seeded
  final batch = FirebaseFirestore.instance.batch();
  for (final idea in _seedIdeas) {
    batch.set(col.doc(), idea);
  }
  await batch.commit();
}

// ─── HomeScreen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int  _selectedIndex = 0;
  bool _drawerOpen    = false;

  late AnimationController _drawerController;
  late Animation<double>   _drawerSlide;

  static const double _navHeight = 64.0;
  static const double _fabSize   = 52.0;

  // ── Stream: approved_ideas ordered newest first ───────────────────────────
  final Stream<QuerySnapshot<Map<String, dynamic>>> _approvedIdeasStream =
  FirebaseFirestore.instance
      .collection('approved_ideas')
      .orderBy('approvedAt', descending: true)
      .snapshots();

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _drawerSlide = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    );
    // Seed dummy ideas into Firestore if the collection is empty
    _seedApprovedIdeasIfEmpty();
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() => _drawerOpen = !_drawerOpen);
    _drawerOpen
        ? _drawerController.forward()
        : _drawerController.reverse();
  }

  void _closeDrawer() {
    if (_drawerOpen) {
      setState(() => _drawerOpen = false);
      _drawerController.reverse();
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 1:
        navigateSmoothly(context, const SearchScreen());
        break;
      case 2:
        navigateSmoothly(context, const SubmitIdeaScreen());
        break;
      case 3:
        navigateSmoothly(context, const LeaderboardScreen());
        break;
      case 4:
        navigateSmoothly(context, const AllBiddingScreen());
        break;
      default:
        setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: colorScheme.surface,
          body: _buildMainContent(context),
          bottomNavigationBar: _buildBottomNav(context),
          floatingActionButton: _buildFAB(context),
          floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
        ),
        if (_drawerOpen)
          GestureDetector(
            onTap: _closeDrawer,
            child: Container(color: colorScheme.scrim.withOpacity(0.35)),
          ),
        AnimatedBuilder(
          animation: _drawerSlide,
          builder: (_, __) => Transform.translate(
            offset: Offset((_drawerSlide.value - 1) * 280, 0),
            child: _buildDrawer(context),
          ),
        ),
      ],
    );
  }

  // ── Main scrollable content ───────────────────────────────────────────────
  Widget _buildMainContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _approvedIdeasStream,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  );
                }

                final docs = snap.data?.docs ?? [];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Text(
                      'Discover Ideas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Explore innovative startup concepts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (docs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lightbulb_outline,
                                size: 52, color: colorScheme.outlineVariant),
                            const SizedBox(height: 12),
                            Text(
                              'No ideas yet',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Be the first to submit an idea!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...docs.map((doc) {
                        final d = doc.data();
                        return GestureDetector(
                          onTap: () => navigateSmoothly(
                            context,
                            IdeaDetailScreen(
                              ideaId:          doc.id,
                              title:           d['title']       as String? ?? '',
                              description:     d['detailedSolution'] as String? ??
                                  d['problemStatement'] as String? ?? '',
                              likes:           d['likes']       as int?    ?? 0,
                              aiRating:        (d['aiRating']   as num?)?.toDouble() ?? 4.0,
                              industry:        d['category']    as String? ?? '',
                              isPatented:      d['isPatented']  as bool?   ?? false,
                              contributorName: d['contributorName'] as String? ?? 'Innovator',
                            ),
                          ),
                          child: _IdeaCardWidget(
                            data: d,
                            docId: doc.id,
                            onBidTap: () => navigateSmoothly(
                              context,
                              IdeaBiddingScreen(
                                  ideaTitle: d['title'] as String? ?? ''),
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Custom AppBar ─────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleDrawer,
            child: Icon(Icons.menu, color: colorScheme.onSurface, size: 26),
          ),
          Expanded(
            child: Center(
              child: Text(
                'InspireX',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => navigateSmoothly(
              context,
              const ProfileScreen(),
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(Icons.person, color: colorScheme.onPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Left Drawer ───────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 16,
      child: SizedBox(
        width: 280,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onPrimary.withOpacity(0.25),
                          ),
                          child: Icon(Icons.person,
                              color: colorScheme.onPrimary, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('John Doe',
                                style: GoogleFonts.plusJakartaSans(
                                    color: colorScheme.onPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            Text('Investor',
                                style: GoogleFonts.plusJakartaSans(
                                    color: colorScheme.onPrimary.withOpacity(0.7), fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _closeDrawer,
                    child: Icon(Icons.close, color: colorScheme.onPrimary, size: 22),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _DrawerItem(
                      icon: Icons.home_outlined,
                      label: 'Home',
                      onTap: () {
                        _closeDrawer();
                      }),
                  _DrawerItem(
                      icon: Icons.trending_up_outlined,
                      label: 'My Ideas',
                      onTap: () {
                        _closeDrawer();
                        navigateSmoothly(context, const MyIdeasScreen());
                      }),
                  _DrawerItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () {
                        _closeDrawer();
                        navigateSmoothly(context, NotificationsScreen(uid: null));
                      }),
                  _DrawerItem(
                      icon: Icons.person_outline,
                      label: 'Profile',
                      onTap: () {
                        _closeDrawer();
                        navigateSmoothly(context, const ProfileScreen());
                      }),
                  _DrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: _closeDrawer),
                  _DrawerItem(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      onTap: _closeDrawer),
                  const _AppearanceToggle(),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
            InkWell(
              onTap: () async {
                _closeDrawer();
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: colorScheme.error, size: 22),
                    const SizedBox(width: 12),
                    Text('Logout',
                        style: GoogleFonts.plusJakartaSans(
                            color: colorScheme.error,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Navigation ─────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(
        bottomAppBarTheme: const BottomAppBarThemeData(height: 64.0),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.scrim.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          color: colorScheme.surface,
          elevation: 0,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 64.0,
            child: Row(
              children: [
                _BottomNavItem(
                    icon: Icons.home,
                    label: 'Home',
                    selected: _selectedIndex == 0,
                    onTap: () => _onBottomNavTap(0)),
                _BottomNavItem(
                    icon: Icons.search,
                    label: 'Search',
                    selected: _selectedIndex == 1,
                    onTap: () => _onBottomNavTap(1)),
                const Expanded(child: SizedBox()),
                _BottomNavItem(
                    icon: Icons.emoji_events_outlined,
                    label: 'Leaderboard',
                    selected: _selectedIndex == 3,
                    onTap: () => _onBottomNavTap(3)),
                _BottomNavItem(
                    icon: Icons.gavel_outlined,
                    label: 'Bidding',
                    selected: _selectedIndex == 4,
                    onTap: () => _onBottomNavTap(4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────
  Widget _buildFAB(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Transform.translate(
      offset: const Offset(0, 12),
      child: GestureDetector(
        onTap: () => _onBottomNavTap(2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52.0,
              height: 52.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: colorScheme.onPrimary, size: 30),
            ),
            const SizedBox(height: 7),
            Text(
              'Submit',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Idea Card Widget (Firestore-backed) ──────────────────────────────────────
class _IdeaCardWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onBidTap;

  const _IdeaCardWidget({
    required this.data,
    required this.docId,
    required this.onBidTap,
  });

  @override
  State<_IdeaCardWidget> createState() => _IdeaCardWidgetState();
}

class _IdeaCardWidgetState extends State<_IdeaCardWidget> {
  Map<String, dynamic>? _mlData;
  bool _loadingML = false;

  @override
  void initState() {
    super.initState();
    _fetchMLInsights();
  }

  Future<void> _fetchMLInsights() async {
    final problem = widget.data['problemStatement'] ?? widget.data['detailedSolution'] ?? '';
    if (problem.isEmpty) return;
    
    setState(() => _loadingML = true);
    final result = await MLService().processIdea(problem);
    if (!mounted) return;
    setState(() {
      _mlData = result;
      _loadingML = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark      = theme.brightness == Brightness.dark;

    final title       = widget.data['title']            as String? ?? 'Untitled';
    final desc        = widget.data['detailedSolution'] as String? ??
        widget.data['problemStatement']                as String? ?? '';
    final likes       = widget.data['likes']            as int?    ?? 0;
    
    // ML values
    final aiRating    = (_mlData?['rating'] as num?)?.toDouble() ?? 
                       (widget.data['aiRating'] as num?)?.toDouble() ?? 4.0;
    final sentiment   = _mlData?['sentiment'] ?? 'Neutral';
    final sentimentScore = (_mlData?['sentiment_score'] as num?)?.toDouble() ?? 0.0;
    final summary     = _mlData?['summary'] ?? desc;

    final industry    = widget.data['category']         as String? ?? '';
    final isPatented  = widget.data['isPatented']       as bool?   ?? false;
    final contributor = widget.data['contributorName'] as String? ?? 'Innovator';

    final tagBg   = _getCategoryTagBg(industry, colorScheme, isDark);
    final tagText = _getCategoryTagText(industry, colorScheme, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.scrim.withOpacity(isDark ? 0.3 : 0.13),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: colorScheme.scrim.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Contributor row ─────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                  ),
                  child: Icon(Icons.person, color: colorScheme.onPrimary, size: 15),
                ),
                const SizedBox(width: 8),
                Text(
                  contributor,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (aiRating > 4.5)
                   _buildHighPotentialBadge(colorScheme),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            // AI Summary
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
                fontStyle: _mlData != null ? FontStyle.italic : null,
              ),
            ),
            const SizedBox(height: 12),

            // ── ML Insights Row ──────────────────────────────────────────
            Row(
              children: [
                _buildInsightChip(
                  icon: Icons.star,
                  label: aiRating.toStringAsFixed(1),
                  color: Colors.amber,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                _buildInsightChip(
                  icon: _getSentimentIcon(sentiment),
                  label: sentiment,
                  color: _getSentimentColor(sentimentScore),
                  colorScheme: colorScheme,
                ),
                const Spacer(),
                Icon(Icons.thumb_up_alt_outlined,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('$likes',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),

            // ── Tags ────────────────────────────────────────────────────
            Row(
              children: [
                if (industry.isNotEmpty)
                  _Tag(
                    label: industry,
                    color: tagBg,
                    textColor: tagText,
                  ),
                if (industry.isNotEmpty) const SizedBox(width: 8),
                _PatentTag(isPatented: isPatented),
              ],
            ),
            const SizedBox(height: 12),

            // ── Price & Timeline Row ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Base Price', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                    Text('₹${(widget.data['basePrice'] as int? ?? 0).toString()}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.primary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bidding Deadline', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                    Text((widget.data['biddingDate'] as String? ?? 'TBD'), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  ],
                ),
                if ((widget.data['aiSuggestedPrice'] as int? ?? 0) > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Suggested', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                      Text('₹${(widget.data['aiSuggestedPrice'] as int? ?? 0).toString()}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.secondary)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // ── CTA ─────────────────────────────────────────────────────
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
                  onPressed: widget.onBidTap,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Interested? Start Bidding',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighPotentialBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange, Colors.red]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'HIGH POTENTIAL',
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }

  Widget _buildInsightChip({required IconData icon, required String label, required Color color, required ColorScheme colorScheme}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment) {
      case 'Positive':
        return Icons.sentiment_satisfied;
      case 'Negative':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getSentimentColor(double sentimentScore) {
    if (sentimentScore >= 0.05) return const Color(0xFF10B981); // Green
    if (sentimentScore <= -0.05) return const Color(0xFFEF4444); // Red
    return const Color(0xFFFBBF24); // Amber
  }
}

// ─── Star Rating ──────────────────────────────────────────────────────────────
class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half   = !filled && (i < rating);
        return Icon(
          half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
          size: 15,
          color: const Color(0xFFFBBF24),
        );
      }),
    );
  }
}

// ─── Tag ──────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Tag(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor)),
    );
  }
}

// ─── Patent Tag ───────────────────────────────────────────────────────────────
class _PatentTag extends StatelessWidget {
  final bool isPatented;
  const _PatentTag({required this.isPatented});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusGreen = const Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPatented
            ? statusGreen.withOpacity(0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPatented ? Icons.verified_outlined : Icons.block_outlined,
            size: 13,
            color: isPatented
                ? statusGreen
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            isPatented ? 'Patented' : 'Not Patented',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isPatented
                  ? statusGreen
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drawer Item ──────────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 22),
            const SizedBox(width: 16),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Nav Item ──────────────────────────────────────────────────────────
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BottomNavItem(
      {required this.icon,
        required this.label,
        required this.selected,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 28,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(height: 1),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Appearance Toggle ────────────────────────────────────────────────────────
class _AppearanceToggle extends StatelessWidget {
  const _AppearanceToggle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Appearance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              _ModernSwitch(
                value: isDark,
                onChanged: (val) => ThemeManager.toggleTheme(val),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModernSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModernSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 46,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.onPrimary,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.scrim.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
