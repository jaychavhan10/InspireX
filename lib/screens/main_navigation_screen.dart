import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/transitions.dart';
import '../theme_manager.dart';
import 'all_bidding_screen.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'search_screen.dart';
import 'submit_idea_screen.dart';
import 'profile_screen.dart';
import 'my_ideas_screen.dart';
import 'notifications_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  static const int _pageCount = 4;
  static const double _navHeight = 64.0;

  late final PageController _pageController;
  late int _currentIndex;
  
  // Drawer state
  late AnimationController _drawerController;
  late Animation<double> _drawerSlide;
  bool _drawerOpen = false;

  // Lazy initialize each page once, then keep it cached for smooth swiping.
  final Map<int, Widget> _cachedPages = <int, Widget>{};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pageCount - 1).toInt();
    _pageController = PageController(initialPage: _currentIndex);
    
    // Drawer animation
    _drawerController = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
    _drawerSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _drawerController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _pageController.dispose();
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

  Widget _buildPage(int index) {
    return _cachedPages.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return HomeScreen(showNavigation: false, onDrawerToggle: _toggleDrawer);
        case 1:
          return SearchScreen(showNavigation: false, onDrawerToggle: _toggleDrawer);
        case 2:
          return LeaderboardScreen(showNavigation: false, onDrawerToggle: _toggleDrawer);
        case 3:
          return AllBiddingScreen(showNavigation: false, onDrawerToggle: _toggleDrawer);
        default:
          return const SizedBox.shrink();
      }
    });
  }

  void _onPageChanged(int index) {
    if (!mounted || _currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  Future<void> _onBottomNavTap(int index) async {
    if (index == _currentIndex) return;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _openSubmitIdea() {
    navigateSmoothly(context, const SubmitIdeaScreen());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final scaffold = Scaffold(
      backgroundColor: colorScheme.surface,
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
      body: GestureDetector(
        // Explicitly consume horizontal drag gestures to prevent drawer edge detection
        onHorizontalDragStart: (_) {},
        onHorizontalDragUpdate: (_) {},
        onHorizontalDragEnd: (_) {},
        onHorizontalDragCancel: () {},
        behavior: HitTestBehavior.translucent,
        child: PageView.builder(
          controller: _pageController,
          physics: const PageScrollPhysics(),
          allowImplicitScrolling: true,
          onPageChanged: _onPageChanged,
          itemCount: _pageCount,
          itemBuilder: (context, index) => KeyedSubtree(
            key: PageStorageKey<String>('main-page-$index'),
            child: _buildPage(index),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(colorScheme),
      floatingActionButton: _buildSubmitFab(colorScheme),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
    
    return Stack(
      children: [
        scaffold,
        
        if (_drawerOpen)
          GestureDetector(
            onTap: _closeDrawer,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
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
              color: colorScheme.scrim.withValues(alpha: 0.08),
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
                _MainBottomNavItem(
                  icon: Icons.home,
                  selected: _currentIndex == 0,
                  onTap: () => _onBottomNavTap(0),
                ),
                _MainBottomNavItem(
                  icon: Icons.search,
                  selected: _currentIndex == 1,
                  onTap: () => _onBottomNavTap(1),
                ),
                const Expanded(child: SizedBox()),
                _MainBottomNavItem(
                  icon: Icons.emoji_events_outlined,
                  selected: _currentIndex == 2,
                  onTap: () => _onBottomNavTap(2),
                ),
                _MainBottomNavItem(
                  icon: Icons.gavel_outlined,
                  selected: _currentIndex == 3,
                  onTap: () => _onBottomNavTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitFab(ColorScheme colorScheme) {
    return Transform.translate(
      offset: const Offset(0, 12),
      child: GestureDetector(
        onTap: _openSubmitIdea,
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
                    color: colorScheme.primary.withValues(alpha: 0.3),
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
              style: GoogleFonts.plusJakartaSans(
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

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      elevation: 16,
      color: isDark ? colorScheme.surface : Colors.white,
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
                            color: Colors.white.withOpacity(0.25),
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('John Doe',
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            Text('Investor',
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _closeDrawer,
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _MainDrawerItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    onTap: () {
                      _closeDrawer();
                      _onBottomNavTap(0);
                    },
                  ),
                  _MainDrawerItem(
                    icon: Icons.trending_up_outlined,
                    label: 'My Ideas',
                    onTap: () {
                      _closeDrawer();
                      navigateSmoothly(context, const MyIdeasScreen());
                    },
                  ),
                  _MainDrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {
                      _closeDrawer();
                      navigateSmoothly(context, NotificationsScreen(uid: null));
                    },
                  ),
                  _MainDrawerItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () {
                      _closeDrawer();
                      navigateSmoothly(context, const ProfileScreen());
                    },
                  ),
                  _MainDrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: _closeDrawer),
                  _MainDrawerItem(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      onTap: _closeDrawer),
                  const _MainAppearanceToggle(),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? colorScheme.outline : const Color(0xFFE5E7EB)),
            InkWell(
              onTap: () async {
                _closeDrawer();
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
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
}

class _MainBottomNavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MainBottomNavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _MainDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MainDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 22,
                color: isDark
                    ? colorScheme.onSurfaceVariant
                    : const Color(0xFF6B7280)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? colorScheme.onSurface
                          : const Color(0xFF1F2937))),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainAppearanceToggle extends StatelessWidget {
  const _MainAppearanceToggle();

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
              _MainModernSwitch(
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

class _MainModernSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MainModernSwitch({required this.value, required this.onChanged});

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
