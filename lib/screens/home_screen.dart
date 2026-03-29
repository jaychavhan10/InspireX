import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'search_screen.dart';
import 'submit_idea_screen.dart';
import 'leaderboard_screen.dart';
import 'all_bidding_screen.dart';
import 'profile_screen.dart';
import 'idea_bidding_screen.dart';
import 'idea_detail_screen.dart';
// ─── Placeholder screens (stubs) ───────────────────────────────────────────



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

// ─── Data model ────────────────────────────────────────────────────────────
class IdeaCard {
  final String title;
  final String description;
  final int likes;
  final double aiRating;
  final String industry;
  final bool isPatented;

  const IdeaCard({
    required this.title,
    required this.description,
    required this.likes,
    required this.aiRating,
    required this.industry,
    required this.isPatented,
  });
}

// ─── Sample data ───────────────────────────────────────────────────────────
final List<IdeaCard> _seedIdeas = [
  IdeaCard(
    title: 'AI-Powered Meal Planning Assistant',
    description:
    'An intelligent system that creates personalized meal plans based on dietary restrictions, budget, and nutritional goals.',
    likes: 245,
    aiRating: 4.5,
    industry: 'Food',
    isPatented: true,
  ),
  IdeaCard(
    title: 'Blockchain-Based Supply Chain Tracker',
    description:
    'Real-time tracking solution for supply chain management using blockchain technology to ensure transparency.',
    likes: 189,
    aiRating: 4.2,
    industry: 'Blockchain',
    isPatented: false,
  ),
  IdeaCard(
    title: 'Smart Home Energy Optimizer',
    description:
    'IoT device that learns your energy consumption patterns and automatically optimizes power usage across appliances.',
    likes: 312,
    aiRating: 4.7,
    industry: 'IoT',
    isPatented: true,
  ),
  IdeaCard(
    title: 'AR-Powered Interior Design Tool',
    description:
    'Augmented reality application that lets users visualize furniture and décor in their actual living space before buying.',
    likes: 178,
    aiRating: 4.0,
    industry: 'AR / VR',
    isPatented: false,
  ),
];

final List<IdeaCard> _moreIdeas = [
  IdeaCard(
    title: 'EduBot – Adaptive Learning Platform',
    description:
    'AI tutor that adapts content difficulty in real-time based on student performance metrics and learning pace.',
    likes: 421,
    aiRating: 4.8,
    industry: 'EdTech',
    isPatented: true,
  ),
  IdeaCard(
    title: 'Carbon Footprint Wallet',
    description:
    'A digital wallet that calculates and offsets the carbon footprint of every transaction you make automatically.',
    likes: 156,
    aiRating: 3.9,
    industry: 'CleanTech',
    isPatented: false,
  ),
];

// ─── Constants ─────────────────────────────────────────────────────────────
const _purple = Color(0xFF7C3AED);
const _purpleLight = Color(0xFF8B5CF6);
const _gradientStart = Color(0xFF7C3AED);
const _gradientEnd = Color(0xFF3B82F6);
const _bgColor = Color(0xFFF8FAFC);

// ─── HomeScreen ────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _drawerOpen = false;
  late List<IdeaCard> _ideas;
  bool _loadingMore = false;
  bool _allLoaded = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerSlide;

  static const double _navHeight = 64.0;
  static const double _fabSize = 52.0;
  // How far above the bottom the FAB circle centre sits
  static const double _fabBottomOffset = (_navHeight / 2) + 4;

  @override
  void initState() {
    super.initState();
    _ideas = List.from(_seedIdeas);
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

  Future<void> _refreshFeed() async {
    if (_loadingMore || _allLoaded) return;
    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _ideas.addAll(_moreIdeas);
      _loadingMore = false;
      _allLoaded = true;
    });
  }

  void _onBottomNavTap(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SearchScreen()));
        break;
      case 2:
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubmitIdeaScreen()));
        break;
      case 3:
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
        break;
      case 4:
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AllBiddingScreen()));
        break;
      default:
        setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── 1. The actual Scaffold — nav bar + FAB stay exactly as before ──
        Scaffold(
          backgroundColor: _bgColor,
          body: _buildMainContent(),
          bottomNavigationBar: _buildBottomNav(),
          floatingActionButton: _buildFAB(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),

        // ── 2. Scrim — floats over Scaffold including nav bar ──────────────
        if (_drawerOpen)
          GestureDetector(
            onTap: _closeDrawer,
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

        // ── 3. Drawer — topmost layer ──────────────────────────────────────
        AnimatedBuilder(
          animation: _drawerSlide,
          builder: (_, __) => Transform.translate(
            offset: Offset((_drawerSlide.value - 1) * 280, 0),
            child: _buildDrawer(),
          ),
        ),
      ],
    );
  }

  // ── Main scrollable content ───────────────────────────────────────────────
  Widget _buildMainContent() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(
                  'Discover Ideas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Explore innovative startup concepts',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),

                ..._ideas.map((idea) => GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IdeaDetailScreen(
                        title: idea.title,
                        description: idea.description,
                        likes: idea.likes,
                        aiRating: idea.aiRating,
                        industry: idea.industry,
                        isPatented: idea.isPatented,
                        contributorName: 'John Doe',
                      ),
                    ),
                  ),
                  child: _IdeaCardWidget(
                    idea: idea,
                    onBidTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IdeaBiddingScreen(ideaTitle: idea.title),
                      ),
                    ),
                  ),
                )),

                const SizedBox(height: 8),

                if (!_allLoaded)
                  _RefreshFeedButton(
                    loading: _loadingMore,
                    onTap: _refreshFeed,
                  ),

                if (_allLoaded)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        "You've seen all ideas 🎉",
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Custom AppBar ─────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleDrawer,
            child:
            const Icon(Icons.menu, color: Color(0xFF374151), size: 26),
          ),
          Expanded(
            child: Center(
              child: Text(
                'InspireX',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _purple,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_gradientStart, _gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child:
              const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Left Drawer ───────────────────────────────────────────────────────────
  Widget _buildDrawer() {
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_gradientStart, _gradientEnd],
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
                  _DrawerItem(
                      icon: Icons.home_outlined,
                      label: 'Home',
                      onTap: _closeDrawer),
                  _DrawerItem(
                      icon: Icons.trending_up_outlined,
                      label: 'My Ideas',
                      onTap: _closeDrawer),
                  _DrawerItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: _closeDrawer),
                  _DrawerItem(
                      icon: Icons.person_outline,
                      label: 'Profile',
                      onTap: () {
                        _closeDrawer();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                        );
                      }),
                  _DrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: _closeDrawer),
                  _DrawerItem(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      onTap: _closeDrawer),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            InkWell(
              onTap: () {},
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    const Icon(Icons.logout,
                        color: Colors.redAccent, size: 22),
                    const SizedBox(width: 12),
                    Text('Logout',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.redAccent,
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
  Widget _buildBottomNav() {
    return Theme(
      data: Theme.of(context).copyWith(
        bottomAppBarTheme: const BottomAppBarTheme(height: _navHeight),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          color: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: _navHeight,
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

  // ── FAB (Submit Idea) ─────────────────────────────────────────────────────
  Widget _buildFAB() {
    return Transform.translate(
      offset: const Offset(0, 12), // ← increase this to push further down
      child: GestureDetector(
        onTap: () => _onBottomNavTap(2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _fabSize,
              height: _fabSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_gradientStart, _gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x557C3AED),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 7),
            const Text(
              'Submit',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Idea Card Widget ───────────────────────────────────────────────────────
class _IdeaCardWidget extends StatelessWidget {
  final IdeaCard idea;
  final VoidCallback onBidTap;

  const _IdeaCardWidget({required this.idea, required this.onBidTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              idea.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),

            Text(
              idea.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.thumb_up_alt_outlined,
                    size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text('${idea.likes}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                Text('AI Rating:',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: const Color(0xFF6B7280))),
                const SizedBox(width: 4),
                _StarRating(rating: idea.aiRating),
                const SizedBox(width: 4),
                Text(idea.aiRating.toStringAsFixed(1),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                _Tag(
                    label: idea.industry,
                    color: const Color(0xFFFFF3E0),
                    textColor: const Color(0xFFE65100)),
                const SizedBox(width: 8),
                _PatentTag(isPatented: idea.isPatented),
              ],
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_gradientStart, _gradientEnd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: onBidTap,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
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
}

// ─── Star Rating ────────────────────────────────────────────────────────────
class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && (i < rating);
        return Icon(
          half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
          size: 15,
          color: const Color(0xFFF59E0B),
        );
      }),
    );
  }
}

// ─── Tag Widget ─────────────────────────────────────────────────────────────
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

// ─── Patent Tag ─────────────────────────────────────────────────────────────
class _PatentTag extends StatelessWidget {
  final bool isPatented;
  const _PatentTag({required this.isPatented});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPatented
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPatented ? Icons.verified_outlined : Icons.block_outlined,
            size: 13,
            color: isPatented
                ? const Color(0xFF2E7D32)
                : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(
            isPatented ? 'Patented' : 'Not Patented',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isPatented
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Refresh Feed Button ────────────────────────────────────────────────────
class _RefreshFeedButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _RefreshFeedButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _purpleLight, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _purple.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: loading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _purple),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh, color: _purple, size: 18),
              const SizedBox(width: 6),
              Text('Refresh Feed',
                  style: GoogleFonts.plusJakartaSans(
                      color: _purple,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Drawer Item ────────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: _purple, size: 22),
            const SizedBox(width: 16),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: const Color(0xFF374151),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Nav Item ────────────────────────────────────────────────────────
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
                color: selected ? _purple : const Color(0xFF9CA3AF)),
            const SizedBox(height: 1),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? _purple : const Color(0xFF9CA3AF),
                  fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}
