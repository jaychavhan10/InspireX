import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_manager.dart';
import 'search_screen.dart';
import 'leaderboard_screen.dart';
import 'submit_idea_screen.dart';
import 'my_ideas_screen.dart';
import 'profile_screen.dart';
import 'idea_bidding_screen.dart';
import 'idea_detail_screen.dart';
import '../utils/transitions.dart';

// ─── Data model ─────────────────────────────────────────────────────────────
enum BidStatus { live, upcoming, past }

class BiddingItem {
  final String id;
  final String title;
  final String category;
  final int currentBid;
  final int basePrice;
  final int participants;
  final BidStatus status;
  final String timeInfo;
  final bool isPatented;

  const BiddingItem({
    required this.id,
    required this.title,
    required this.category,
    required this.currentBid,
    required this.basePrice,
    required this.participants,
    required this.status,
    required this.timeInfo,
    required this.isPatented,
  });
}

// ─── Sample data ─────────────────────────────────────────────────────────────
final List<BiddingItem> _allBiddings = [
  BiddingItem(
    id: '1',
    title: 'AI-Powered Content Generator',
    category: 'AI',
    currentBid: 185000,
    basePrice: 120000,
    participants: 12,
    status: BidStatus.live,
    timeInfo: '45 mins remaining',
    isPatented: true,
  ),
  BiddingItem(
    id: '2',
    title: 'Smart Parking Management System',
    category: 'IoT',
    currentBid: 95000,
    basePrice: 70000,
    participants: 8,
    status: BidStatus.live,
    timeInfo: '1h 20m remaining',
    isPatented: false,
  ),
  BiddingItem(
    id: '3',
    title: 'Eco-Friendly Water Purifier',
    category: 'Sustainability',
    currentBid: 142000,
    basePrice: 100000,
    participants: 15,
    status: BidStatus.live,
    timeInfo: '25 mins remaining',
    isPatented: true,
  ),
  BiddingItem(
    id: '4',
    title: 'AR Shopping Experience App',
    category: 'AI',
    currentBid: 0,
    basePrice: 150000,
    participants: 0,
    status: BidStatus.upcoming,
    timeInfo: 'Tomorrow at 3:00 PM',
    isPatented: true,
  ),
  BiddingItem(
    id: '5',
    title: 'Personalized Fitness AI Coach',
    category: 'Healthcare',
    currentBid: 0,
    basePrice: 90000,
    participants: 0,
    status: BidStatus.upcoming,
    timeInfo: 'Nov 29 at 10:00 AM',
    isPatented: false,
  ),
  BiddingItem(
    id: '6',
    title: 'Blockchain Voting System',
    category: 'Blockchain',
    currentBid: 420000,
    basePrice: 200000,
    participants: 24,
    status: BidStatus.past,
    timeInfo: 'Ended Nov 25',
    isPatented: true,
  ),
  BiddingItem(
    id: '7',
    title: 'Smart Waste Segregation Robot',
    category: 'IoT',
    currentBid: 275000,
    basePrice: 180000,
    participants: 18,
    status: BidStatus.past,
    timeInfo: 'Ended Nov 22',
    isPatented: true,
  ),
];

// ─── Constants ────────────────────────────────────────────────────────────────
// Category color mapping helpers (consistent with home_screen and idea_detail)
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

// ─── AllBiddingScreen ─────────────────────────────────────────────────────────
class AllBiddingScreen extends StatefulWidget {
  const AllBiddingScreen({super.key});

  @override
  State<AllBiddingScreen> createState() => _AllBiddingScreenState();
}

class _AllBiddingScreenState extends State<AllBiddingScreen>
    with SingleTickerProviderStateMixin {
  BidStatus _activeTab = BidStatus.live;
  bool _drawerOpen = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerSlide;

  static const double _navHeight = 64.0;

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
    if (index == 4) return; // already on bidding
    switch (index) {
      case 0:
        Navigator.popUntil(context, (r) => r.isFirst);
        break;
      case 1:
        navigateSmoothly(context, const SearchScreen(), replacement: true);
        break;
      case 2:
        navigateSmoothly(context, const SubmitIdeaScreen());
        break;
      case 3:
        navigateSmoothly(context, const LeaderboardScreen(), replacement: true);
        break;
    }
  }

  List<BiddingItem> get _filtered =>
      _allBiddings.where((b) => b.status == _activeTab).toList();

  String get _tabTitle {
    switch (_activeTab) {
      case BidStatus.live:
        return 'Live Bidding Sessions';
      case BidStatus.upcoming:
        return 'Upcoming Bidding Sessions';
      case BidStatus.past:
        return 'Past Bidding Sessions';
    }
  }

  String get _tabSubtitle {
    final count = _filtered.length;
    switch (_activeTab) {
      case BidStatus.live:
        return '$count active bidding${count != 1 ? 's' : ''}';
      case BidStatus.upcoming:
        return '$count upcoming bidding${count != 1 ? 's' : ''}';
      case BidStatus.past:
        return '$count past bidding${count != 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // ── 1. Scaffold ───────────────────────────────────────────────────
        Scaffold(
          backgroundColor: colorScheme.surface,
          body: _buildMainContent(colorScheme, isDark),
          bottomNavigationBar: _buildBottomNav(colorScheme),
          floatingActionButton: _buildFAB(colorScheme),
          floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
        ),

        // ── 2. Scrim ──────────────────────────────────────────────────────
        if (_drawerOpen)
          GestureDetector(
            onTap: _closeDrawer,
            child: Container(color: colorScheme.scrim.withOpacity(0.35)),
          ),

        // ── 3. Drawer ─────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _drawerSlide,
          builder: (_, __) => Transform.translate(
            offset: Offset((_drawerSlide.value - 1) * 280, 0),
            child: _buildDrawer(colorScheme),
          ),
        ),
      ],
    );
  }

  // ── Main content ──────────────────────────────────────────────────────────
  Widget _buildMainContent(ColorScheme colorScheme, bool isDark) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // AppBar
          _buildAppBar(colorScheme),
          // Sticky tab row
          _buildTabBar(colorScheme),
          // Scrollable list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                // Section title
                Text(
                  _tabTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tabSubtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ..._filtered.map(
                      (item) => _BiddingCard(
                    item: item,
                    onTap: () {
                      if (item.status == BidStatus.live) {
                        navigateSmoothly(
                          context,
                          IdeaBiddingScreen(ideaTitle: item.title),
                        );
                      } else if (item.status == BidStatus.upcoming) {
                        navigateSmoothly(
                          context,
                          IdeaDetailScreen(
                            ideaId: item.id,
                            title: item.title,
                            description: 'Fetching full details...',
                            likes: 0,
                            aiRating: 4.5,
                            industry: item.category,
                            isPatented: item.isPatented,
                            contributorName: 'Innovator',
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar (identical to home_screen.dart) ────────────────────────────────
  Widget _buildAppBar(ColorScheme colorScheme) {
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

  // ── Tab bar (Live / Soon to Start / Past Bids) ────────────────────────────
  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _TabButton(
              label: 'Live Bidding',
              selected: _activeTab == BidStatus.live,
              selectedColor: const Color(0xFF16A34A),
              onTap: () => setState(() => _activeTab = BidStatus.live),
            ),
            _TabButton(
              label: 'Soon to Start',
              selected: _activeTab == BidStatus.upcoming,
              selectedColor: colorScheme.primary,
              onTap: () => setState(() => _activeTab = BidStatus.upcoming),
            ),
            _TabButton(
              label: 'Past Bids',
              selected: _activeTab == BidStatus.past,
              selectedColor: colorScheme.onSurface,
              onTap: () => setState(() => _activeTab = BidStatus.past),
            ),
          ],
        ),
      ),
    );
  }

  // ── Left Drawer (identical to home_screen.dart) ───────────────────────────
  Widget _buildDrawer(ColorScheme colorScheme) {
    return Material(
      elevation: 16,
      child: Container(
        width: 280,
        height: double.infinity,
        color: colorScheme.surface,
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
                                    color: colorScheme.onPrimary.withOpacity(0.7),
                                    fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _closeDrawer,
                    child: Icon(Icons.close,
                        color: colorScheme.onPrimary, size: 22),
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
                      Navigator.popUntil(
                          context, (route) => route.isFirst);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.trending_up_outlined,
                    label: 'My Ideas',
                    onTap: () {
                      _closeDrawer();
                      navigateSmoothly(context, const MyIdeasScreen());
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {
                      _closeDrawer();
                      // Assuming NotificationsScreen is defined elsewhere or handled by another route
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () {
                      _closeDrawer();
                      navigateSmoothly(context, const ProfileScreen());
                    },
                  ),
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
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    Icon(Icons.logout,
                        color: colorScheme.error, size: 22),
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

  // ── Bottom Navigation — Bidding tab highlighted ───────────────────────────
  Widget _buildBottomNav(ColorScheme colorScheme) {
    return Theme(
      data: Theme.of(context).copyWith(
        bottomAppBarTheme: const BottomAppBarThemeData(height: _navHeight),
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
            height: _navHeight,
            child: Row(
              children: [
                _BottomNavItem(
                    icon: Icons.home,
                    label: 'Home',
                    selected: false,
                    onTap: () => _onBottomNavTap(0)),
                _BottomNavItem(
                    icon: Icons.search,
                    label: 'Search',
                    selected: false,
                    onTap: () => _onBottomNavTap(1)),
                const Expanded(child: SizedBox()), // FAB notch space
                _BottomNavItem(
                    icon: Icons.emoji_events_outlined,
                    label: 'Leaderboard',
                    selected: false,
                    onTap: () => _onBottomNavTap(3)),
                _BottomNavItem(
                    icon: Icons.gavel_outlined,
                    label: 'Bidding',
                    selected: true, // ← highlighted
                    onTap: () => _onBottomNavTap(4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────
  Widget _buildFAB(ColorScheme colorScheme) {
    return Transform.translate(
      offset: const Offset(0, 12),
      child: GestureDetector(
        onTap: () => _onBottomNavTap(2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.35),
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

// ─── Bidding Card ─────────────────────────────────────────────────────────────
class _BiddingCard extends StatelessWidget {
  final BiddingItem item;
  final VoidCallback onTap;

  const _BiddingCard({required this.item, required this.onTap});

  // Status badge gradient
  List<Color> get _statusColors {
    switch (item.status) {
      case BidStatus.live:
        return [const Color(0xFF16A34A), const Color(0xFF059669)];
      case BidStatus.upcoming:
        return [const Color(0xFF16A34A), const Color(0xFF059669)];
      case BidStatus.past:
        return [const Color(0xFF64748B), const Color(0xFF475569)];
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case BidStatus.live:
        return 'Live';
      case BidStatus.upcoming:
        return 'Upcoming';
      case BidStatus.past:
        return 'Past';
    }
  }

  Widget _statusIcon(ColorScheme colorScheme) {
    switch (item.status) {
      case BidStatus.live:
        return _PulseDot();
      case BidStatus.upcoming:
        return Icon(Icons.calendar_today_outlined,
            color: colorScheme.onPrimary, size: 14);
      case BidStatus.past:
        return Icon(Icons.check_circle_outline,
            color: colorScheme.onPrimary, size: 14);
    }
  }

  Widget _timeIcon(ColorScheme colorScheme) {
    switch (item.status) {
      case BidStatus.live:
        return const Icon(Icons.access_time,
            size: 16, color: Color(0xFFFBBF24));
      case BidStatus.upcoming:
        return Icon(Icons.calendar_today_outlined,
            size: 16, color: colorScheme.primary);
      case BidStatus.past:
        return Icon(Icons.check_circle_outline,
            size: 16, color: colorScheme.onSurfaceVariant);
    }
  }

  // Action button
  Widget _actionButton(VoidCallback onTap, ColorScheme colorScheme) {
    switch (item.status) {
      case BidStatus.live:
        return SizedBox(
          width: double.infinity,
          height: 42,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF059669)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Join Live Bidding',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      case BidStatus.upcoming:
        return SizedBox(
          width: double.infinity,
          height: 42,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF059669)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'View Idea Details',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      case BidStatus.past:
        return SizedBox(
          width: double.infinity,
          height: 42,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'Bidding Ended',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
    }
  }

  String _formatPrice(int price) =>
      '\$${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colorScheme.scrim.withOpacity(0.10),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: colorScheme.scrim.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title + Status badge ────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getCategoryTagBg(item.category, colorScheme, isDark),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.category,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getCategoryTagText(item.category, colorScheme, isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _statusColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _statusIcon(colorScheme),
                      const SizedBox(width: 5),
                      Text(
                        _statusLabel,
                        style: GoogleFonts.plusJakartaSans(
                          color: colorScheme.onPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Price boxes ─────────────────────────────────────────────────
            Row(
              children: [
                // Base Price box
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Base Price',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(
                          _formatPrice(item.basePrice),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Current Bid box — only for live and past
                if (item.status != BidStatus.upcoming) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark 
                              ? [colorScheme.secondaryContainer.withOpacity(0.2), colorScheme.secondaryContainer.withOpacity(0.1)]
                              : [const Color(0xFFF0FDF4), const Color(0xFFECFDF5)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isDark ? colorScheme.secondaryContainer : const Color(0xFF16A34A).withOpacity(0.2), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Bid',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF16A34A))),
                          const SizedBox(height: 2),
                          Text(
                            _formatPrice(item.currentBid),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // ── Time + Participants row ──────────────────────────────────────
            Row(
              children: [
                _timeIcon(colorScheme),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.timeInfo,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (item.status != BidStatus.upcoming) ...[
                  Icon(Icons.trending_up,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${item.participants} participants',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // ── Action button ───────────────────────────────────────────────
            _actionButton(onTap, colorScheme),
          ],
        ),
      ),
    );
  }
}

// ─── Pulse Dot (live indicator) ───────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
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
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
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
    final colorScheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}

// ─── Tab Button ───────────────────────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
              BoxShadow(
                color: colorScheme.scrim.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight:
                selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? selectedColor
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Drawer Item ─────────────────────────────────────────────────────────────
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
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

// ─── Bottom Nav Item ─────────────────────────────────────────────────────────
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
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
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.scrim.withOpacity(0.12),
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
