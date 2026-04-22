import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'search_screen.dart';
import 'all_bidding_screen.dart';
import 'submit_idea_screen.dart';
import 'my_ideas_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../theme_manager.dart';
import '../utils/transitions.dart';

// ─── Data model ─────────────────────────────────────────────────────────────
class SoldIdea {
  final String id;
  final String title;
  final String category;
  final bool isPatented;
  final int soldPrice;
  final String contributor;
  final String buyer;
  final DateTime soldDate;
  final int rank;

  const SoldIdea({
    required this.id,
    required this.title,
    required this.category,
    required this.isPatented,
    required this.soldPrice,
    required this.contributor,
    required this.buyer,
    required this.soldDate,
    required this.rank,
  });
}

// ─── Sample data ─────────────────────────────────────────────────────────────
final List<SoldIdea> _topSoldIdeas = [
  SoldIdea(
    id: '1',
    title: 'AI Code Review Assistant',
    category: 'AI',
    isPatented: true,
    soldPrice: 520000,
    contributor: 'Alex Kumar',
    buyer: 'Microsoft',
    soldDate: DateTime(2024, 11, 15),
    rank: 1,
  ),
  SoldIdea(
    id: '2',
    title: 'Blockchain-Based Supply Chain Tracker',
    category: 'Blockchain',
    isPatented: true,
    soldPrice: 485000,
    contributor: 'Michael Rodriguez',
    buyer: 'IBM',
    soldDate: DateTime(2024, 11, 10),
    rank: 2,
  ),
  SoldIdea(
    id: '3',
    title: 'Smart Home Energy Optimizer',
    category: 'IoT',
    isPatented: true,
    soldPrice: 445000,
    contributor: 'Emily Johnson',
    buyer: 'Google',
    soldDate: DateTime(2024, 11, 8),
    rank: 3,
  ),
  SoldIdea(
    id: '4',
    title: 'Sustainable Packaging Solution',
    category: 'Sustainability',
    isPatented: false,
    soldPrice: 380000,
    contributor: 'Maria Santos',
    buyer: 'Unilever',
    soldDate: DateTime(2024, 11, 5),
    rank: 4,
  ),
  SoldIdea(
    id: '5',
    title: 'Virtual Reality Therapy Platform',
    category: 'Healthcare',
    isPatented: true,
    soldPrice: 365000,
    contributor: 'Dr. James Wilson',
    buyer: 'Meta',
    soldDate: DateTime(2024, 11, 1),
    rank: 5,
  ),
  SoldIdea(
    id: '6',
    title: 'AI-Powered Meal Planning Assistant',
    category: 'Food',
    isPatented: true,
    soldPrice: 325000,
    contributor: 'Sarah Chen',
    buyer: 'Uber Eats',
    soldDate: DateTime(2024, 10, 28),
    rank: 6,
  ),
  SoldIdea(
    id: '7',
    title: 'Autonomous Delivery Drone Network',
    category: 'Automobile',
    isPatented: true,
    soldPrice: 298000,
    contributor: 'Tech Innovations Inc',
    buyer: 'Amazon',
    soldDate: DateTime(2024, 10, 25),
    rank: 7,
  ),
];

// ─── LeaderboardScreen ───────────────────────────────────────────────────────
class LeaderboardScreen extends StatefulWidget {
  final bool showNavigation;
  final VoidCallback? onDrawerToggle;

  const LeaderboardScreen({super.key, this.showNavigation = true, this.onDrawerToggle});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
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
    if (index == 3) return; // already on leaderboard
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
      case 4:
        navigateSmoothly(context, const AllBiddingScreen(), replacement: true);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // When embedded in PageView (showNavigation: false), disable drawer completely
    if (!widget.showNavigation) {
      return Scaffold(
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8FAFC),
        drawerEnableOpenDragGesture: false,
        endDrawerEnableOpenDragGesture: false,
        body: _buildMainContent(colorScheme, isDark),
      );
    }

    // When standalone (showNavigation: true), include drawer
    return Stack(
      children: [
        // ── 1. Scaffold ───────────────────────────────────────────────────
        Scaffold(
          backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8FAFC),
          drawerEnableOpenDragGesture: false,
          endDrawerEnableOpenDragGesture: false,
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
            behavior: HitTestBehavior.opaque,
            child: Container(color: colorScheme.scrim.withValues(alpha: 0.35)),
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

  // ── Main scrollable content ───────────────────────────────────────────────
  Widget _buildMainContent(ColorScheme colorScheme, bool isDark) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildAppBar(colorScheme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildHeader(colorScheme),
                const SizedBox(height: 20),
                ..._topSoldIdeas.map((idea) => _SoldIdeaCard(idea: idea)),
                const SizedBox(height: 8),
                _buildMarketInsights(colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Hamburger → opens drawer (not back navigation)
          GestureDetector(
            onTap: !widget.showNavigation && widget.onDrawerToggle != null
                ? widget.onDrawerToggle
                : _toggleDrawer,
            child:
            Icon(Icons.menu, color: colorScheme.onSurface, size: 26),
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
            onTap: () => navigateSmoothly(context, const ProfileScreen()),
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
              child:
              Icon(Icons.person, color: colorScheme.onPrimary, size: 20),
            ),
          ),
        ],
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
            // Gradient header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onPrimary.withOpacity(0.25),
                          ),
                          child: Icon(Icons.person,
                              color: colorScheme.onPrimary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('John Doe',
                                style: GoogleFonts.plusJakartaSans(
                                    color: colorScheme.onPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            Text('Investor',
                                style: GoogleFonts.plusJakartaSans(
                                    color: colorScheme.onPrimary.withOpacity(0.7),
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _closeDrawer,
                    child: Icon(Icons.close,
                        color: colorScheme.onPrimary, size: 20),
                  ),
                ],
              ),
            ),

            // Menu items
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
                      navigateSmoothly(context, const NotificationsScreen(uid: null));
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

  // ── Bottom Navigation — Leaderboard tab highlighted ───────────────────────
  Widget _buildBottomNav(ColorScheme colorScheme) {
    return Theme(
      data: Theme.of(context).copyWith(
        bottomAppBarTheme:
        const BottomAppBarThemeData(height: _navHeight),
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
                    selected: true, // ← highlighted
                    onTap: () => _onBottomNavTap(3)),
                _BottomNavItem(
                    icon: Icons.gavel_outlined,
                    label: 'Bidding',
                    selected: false,
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
      offset: const Offset(0, 8),
      child: GestureDetector(
        onTap: () => _onBottomNavTap(2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
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
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: colorScheme.onPrimary, size: 24),
            ),
            const SizedBox(height: 4),
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

  // ── Trophy header ─────────────────────────────────────────────────────────
  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(Icons.emoji_events,
              color: colorScheme.onPrimary, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          'Top Sold Ideas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Celebrating the most successful innovations',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Market Insights card ──────────────────────────────────────────────────
  Widget _buildMarketInsights(ColorScheme colorScheme) {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Insights',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _InsightRow(label: 'Total Ideas Sold', value: '127', colorScheme: colorScheme),
          const SizedBox(height: 10),
          _InsightRow(
              label: 'Average Sold Price', value: '\$346,000', colorScheme: colorScheme),
          const SizedBox(height: 10),
          _InsightRow(
            label: 'Highest Bid',
            value: '\$520,000',
            colorScheme: colorScheme,
            valueColor: const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }
}

// ─── Sold Idea Card ──────────────────────────────────────────────────────────
class _SoldIdeaCard extends StatelessWidget {
  final SoldIdea idea;
  const _SoldIdeaCard({required this.idea});

  LinearGradient _rankGradient(ColorScheme colorScheme) {
    if (idea.rank == 1) {
      return const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (idea.rank == 2) {
      return const LinearGradient(
        colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (idea.rank == 3) {
      return const LinearGradient(
        colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return LinearGradient(
      colors: [colorScheme.primary, colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isTopThree = idea.rank <= 3;
    final formattedDate =
        '${idea.soldDate.month}/${idea.soldDate.day}/${idea.soldDate.year}';
    final formattedPrice =
        '\$${idea.soldPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isTopThree
            ? Border.all(
            color: colorScheme.primary.withOpacity(0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.scrim.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: colorScheme.scrim.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Rank badge + title ──────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _rankGradient(colorScheme),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.scrim.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '#${idea.rank}',
                      style: GoogleFonts.plusJakartaSans(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              idea.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              softWrap: true,
                            ),
                          ),
                          if (isTopThree) ...[
                            const SizedBox(width: 4),
                            const Text('🏆',
                                style: TextStyle(fontSize: 14)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by ${idea.contributor}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Details ─────────────────────────────────────────────────────
            _DetailRow(
              label: 'Category:',
              colorScheme: colorScheme,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(isDark ? 0.3 : 1.0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  idea.category,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? colorScheme.primary : colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            _DetailRow(
              label: 'Patent Status:',
              colorScheme: colorScheme,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    idea.isPatented
                        ? Icons.verified_outlined
                        : Icons.block_outlined,
                    size: 14,
                    color: idea.isPatented
                        ? const Color(0xFF16A34A)
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    idea.isPatented ? 'Patented' : 'Not Patented',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: idea.isPatented
                          ? const Color(0xFF16A34A)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            _DetailRow(
              label: 'Buyer:',
              colorScheme: colorScheme,
              child: Text(
                idea.buyer,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),

            _DetailRow(
              label: 'Sold Date:',
              colorScheme: colorScheme,
              child: Text(
                formattedDate,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Sold Price banner ────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [colorScheme.secondaryContainer.withOpacity(0.2), colorScheme.secondaryContainer.withOpacity(0.1)]
                      : [const Color(0xFFF0FDF4), const Color(0xFFECFDF5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? colorScheme.secondaryContainer : const Color(0xFFBBF7D0), width: 1),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.trending_up,
                      color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Sold Price',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? colorScheme.onSecondaryContainer : const Color(0xFF166534),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedPrice,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Row ───────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final Widget child;
  final ColorScheme colorScheme;

  const _DetailRow({required this.label, required this.child, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: child),
      ],
    );
  }
}

// ─── Insight Row ─────────────────────────────────────────────────────────────
class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final ColorScheme colorScheme;

  const _InsightRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
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
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(width: 16),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
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
        child: Center(
          child: Icon(icon,
              size: 24,
              color:
              selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Appearance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
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
