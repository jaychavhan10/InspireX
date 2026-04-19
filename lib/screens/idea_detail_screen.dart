import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'idea_bidding_screen.dart';
import '../utils/transitions.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
// Colors are now derived from the theme color scheme.

// ─── Fallback content for seeded/dummy ideas ──────────────────────────────────
const _fallbackProblem =
    'Current solutions in this space are either too expensive, lack scalability, '
    "or don't address the core pain points of end users. There's a significant "
    'gap in the market for an accessible, user-friendly solution.';

const _fallbackSolution =
    'This innovative approach combines cutting-edge technology with practical '
    'implementation. The solution has been tested with focus groups and shows '
    'promising results. Key features include automated workflows, real-time '
    'analytics, and seamless integration capabilities.';

const _fallbackBiddingTime = 'Tomorrow at 3:00 - 4:00 PM';

// ─── IdeaDetailScreen ─────────────────────────────────────────────────────────
class IdeaDetailScreen extends StatefulWidget {
  final String ideaId;
  final String title;
  final String description;
  final int    likes;
  final double aiRating;
  final String industry;
  final bool   isPatented;
  final String contributorName;

  const IdeaDetailScreen({
    super.key,
    required this.ideaId,
    required this.title,
    required this.description,
    required this.likes,
    required this.aiRating,
    required this.industry,
    required this.isPatented,
    required this.contributorName,
  });

  @override
  State<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends State<IdeaDetailScreen> {
  bool _isLiked      = false;
  bool _isInterested = false;
  late int _likeCount;
  late int _interestedCount;

  // ── Fields populated from Firestore ───────────────────────────────────────
  String  _problemStatement  = '';
  String  _detailedSolution  = '';
  String  _biddingSchedule   = '';
  int     _basePrice         = 0;
  bool    _isLoading         = true;
  
  // ── ML Insights ────────────────────────────────────────────────────────────
  String  _mlSummary         = '';
  String  _sentiment         = '';
  String  _similarityStatus  = '';
  bool    _mlLoading         = false;

  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _likeCount       = widget.likes;
    _interestedCount = 0;
    _loadIdeaData();
  }

  // ── Load full idea data from Firestore ────────────────────────────────────
  Future<void> _loadIdeaData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('approved_ideas')
          .doc(widget.ideaId)
          .get();

      if (!doc.exists || !mounted) {
        setState(() => _isLoading = false);
        return;
      }

      final d = doc.data()!;

      // ── Interaction state ────────────────────────────────────────────
      final likedBy      = List<String>.from(d['likedBy']      ?? []);
      final interestedBy = List<String>.from(d['interestedBy'] ?? []);

      // ── Content fields ────────────────────────────────────────────────
      final problem  = d['problemStatement'] as String? ?? '';
      final solution = d['detailedSolution'] as String? ?? '';
      final isSeeded = d['isSeeded']         as bool?   ?? false;

      // Build bidding schedule string
      final bDate = d['biddingDate'] as String? ?? '';
      final bTime = d['biddingTime'] as String? ?? '';
      final String schedule;
      if (bDate.isNotEmpty && bTime.isNotEmpty) {
        schedule = '$bDate  •  $bTime';
      } else if (bDate.isNotEmpty) {
        schedule = bDate;
      } else if (bTime.isNotEmpty) {
        schedule = bTime;
      } else {
        schedule = _fallbackBiddingTime;
      }

      // Base price: use stored value, fall back to patent-based default
      final storedPrice = d['basePrice'] as int? ?? 0;
      final computedPrice = storedPrice > 0
          ? storedPrice
          : (widget.isPatented ? 150000 : 85000);

      setState(() {
        _likeCount       = d['likes']      as int? ?? widget.likes;
        _interestedCount = d['interested'] as int? ?? 0;
        _isLiked         = _uid != null && likedBy.contains(_uid);
        _isInterested    = _uid != null && interestedBy.contains(_uid);

        // For seeded/dummy ideas use fallback copy; for real submissions
        // use what the user actually wrote.
        _problemStatement = (isSeeded || problem.isEmpty)
            ? _fallbackProblem
            : problem;
        _detailedSolution = (isSeeded || solution.isEmpty)
            ? _fallbackSolution
            : solution;

        _biddingSchedule = schedule;
        _basePrice       = computedPrice;
        _isLoading       = false;
      });
      
      // Load ML insights after idea data
      _loadMLInsights();
    } catch (_) {
      if (mounted) {
        setState(() {
          _problemStatement = _fallbackProblem;
          _detailedSolution = _fallbackSolution;
          _biddingSchedule  = _fallbackBiddingTime;
          _basePrice        = widget.isPatented ? 150000 : 85000;
          _isLoading        = false;
        });
      }
    }
  }

  // ── Load ML insights from backend ──────────────────────────────────────────
  Future<void> _loadMLInsights() async {
    try {
      setState(() => _mlLoading = true);
      
      final response = await http.post(
        Uri.parse('http://192.168.1.7:5000/process'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': _detailedSolution}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _mlSummary = data['summary'] ?? '';
          _sentiment = data['sentiment'] ?? '';
          _similarityStatus = data['similarity_status'] ?? '';
          _mlLoading = false;
        });
      } else if (mounted) {
        setState(() => _mlLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _mlLoading = false);
      }
    }
  }

  // ── Toggle like ────────────────────────────────────────────────────────────
  Future<void> _toggleLike() async {
    if (_uid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('approved_ideas')
        .doc(widget.ideaId);

    setState(() {
      _isLiked   = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      if (_isLiked) {
        await ref.update({
          'likes':   FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([_uid]),
        });
      } else {
        await ref.update({
          'likes':   FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([_uid]),
        });
      }

      // Mirror likes back to owner's idea sub-collection
      final ownerUid = (await ref.get()).data()?['uid'] as String?;
      if (ownerUid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUid)
            .collection('ideas')
            .doc(widget.ideaId)
            .update({'likes': FieldValue.increment(_isLiked ? 1 : -1)})
            .catchError((_) {});
      }
    } catch (_) {
      setState(() {
        _isLiked   = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    }
  }

  // ── Toggle interested ──────────────────────────────────────────────────────
  Future<void> _toggleInterested() async {
    if (_uid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('approved_ideas')
        .doc(widget.ideaId);

    setState(() {
      _isInterested    = !_isInterested;
      _interestedCount += _isInterested ? 1 : -1;
    });

    try {
      if (_isInterested) {
        await ref.update({
          'interested':   FieldValue.increment(1),
          'interestedBy': FieldValue.arrayUnion([_uid]),
        });
      } else {
        await ref.update({
          'interested':   FieldValue.increment(-1),
          'interestedBy': FieldValue.arrayRemove([_uid]),
        });
      }

      // Mirror to owner's idea sub-collection
      final ownerUid = (await ref.get()).data()?['uid'] as String?;
      if (ownerUid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUid)
            .collection('ideas')
            .doc(widget.ideaId)
            .update({
          'interested': FieldValue.increment(_isInterested ? 1 : -1),
        })
            .catchError((_) {});
      }
    } catch (_) {
      setState(() {
        _isInterested    = !_isInterested;
        _interestedCount += _isInterested ? 1 : -1;
      });
    }
  }

  // ── Category colour helpers ────────────────────────────────────────────────
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

  String _formatPrice(int price) => '\$${price
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // ── AppBar ───────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Container(
              color: colorScheme.surface,
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back,
                        color: colorScheme.onSurface, size: 24),
                  ),
                  Text(
                    'Idea Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
                : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [_buildMainCard(colorScheme)],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isLoading ? null : _buildBottomCTA(colorScheme),
    );
  }

  // ── Main card ─────────────────────────────────────────────────────────────
  Widget _buildMainCard(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tagBg   = _getCategoryTagBg(widget.industry, colorScheme, isDark);
    final tagText = _getCategoryTagText(widget.industry, colorScheme, isDark);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.scrim.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Contributor ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.person, color: colorScheme.onPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contributorName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Contributor',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Title ──────────────────────────────────────────────────────
          Text(
            widget.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // ── ML Summary ─────────────────────────────────────────────────
          if (_mlSummary.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'AI Summary',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _mlSummary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else if (_mlLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 20,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // ── ML Insights - Sentiment & Similarity ───────────────────────
          if (_sentiment.isNotEmpty || _similarityStatus.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (_sentiment.isNotEmpty)
                  _Pill(
                    icon: _sentiment == 'Positive'
                        ? Icons.sentiment_satisfied
                        : _sentiment == 'Negative'
                            ? Icons.sentiment_dissatisfied
                            : Icons.sentiment_neutral,
                    label: _sentiment,
                    bgColor: _sentiment == 'Positive'
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : _sentiment == 'Negative'
                            ? const Color(0xFFEF4444).withOpacity(0.1)
                            : colorScheme.surfaceContainerHighest,
                    textColor: _sentiment == 'Positive'
                        ? const Color(0xFF10B981)
                        : _sentiment == 'Negative'
                            ? const Color(0xFFEF4444)
                            : colorScheme.onSurfaceVariant,
                  ),
                if (_similarityStatus.isNotEmpty)
                  _Pill(
                    label: _similarityStatus,
                    bgColor: _similarityStatus.contains('Low')
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : _similarityStatus.contains('High')
                            ? const Color(0xFFEF4444).withOpacity(0.1)
                            : const Color(0xFFF59E0B).withOpacity(0.1),
                    textColor: _similarityStatus.contains('Low')
                        ? const Color(0xFF10B981)
                        : _similarityStatus.contains('High')
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B),
                  ),
              ],
            ),
          const SizedBox(height: 12),

          // ── Tags ───────────────────────────────────────────────────────
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _Pill(
                label: widget.industry,
                bgColor: tagBg,
                textColor: tagText,
              ),
              _Pill(
                icon: widget.isPatented
                    ? Icons.verified_outlined
                    : Icons.block_outlined,
                label: widget.isPatented ? 'Patented' : 'Not Patented',
                bgColor: widget.isPatented
                    ? const Color(0xFF16A34A).withOpacity(0.1)
                    : colorScheme.surfaceContainerHighest,
                textColor: widget.isPatented
                    ? const Color(0xFF16A34A)
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── AI Rating ──────────────────────────────────────────────────
          Row(
            children: [
              Text('AI Rating:',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: colorScheme.onSurfaceVariant)),
              const SizedBox(width: 8),
              _StarRating(rating: widget.aiRating),
              const SizedBox(width: 6),
              Text(
                widget.aiRating.toStringAsFixed(1),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Problem Statement ──────────────────────────────────────────
          Text(
            'Problem Statement',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            _problemStatement,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.6),
          ),
          const SizedBox(height: 20),

          // ── Overview / Detailed Solution ───────────────────────────────
          Text(
            'Overview',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            _detailedSolution,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.6),
          ),
          const SizedBox(height: 6),
          Text(
            'Full details will be revealed to the winning bidder',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),

          // ── Base Price ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.secondaryContainer.withOpacity(0.3)
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Base Price',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(_basePrice),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Bidding Schedule ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: colorScheme.tertiaryContainer, width: 1),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Text(
                      'Bidding Schedule',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.tertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_outlined,
                        size: 16, color: colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _biddingSchedule,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: colorScheme.onTertiaryContainer),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Divider(color: colorScheme.outlineVariant, height: 1),
          const SizedBox(height: 16),

          // ── Likes + Interested count ───────────────────────────────────
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined,
                  size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_likeCount ${_likeCount == 1 ? 'person' : 'people'} liked'
                      '  •  $_interestedCount interested',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Action buttons ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _toggleLike,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isLiked
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isLiked
                              ? Icons.thumb_up_alt
                              : Icons.thumb_up_alt_outlined,
                          size: 16,
                          color: _isLiked
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isLiked ? 'Liked' : 'Like',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isLiked
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _toggleInterested,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isInterested
                          ? colorScheme.secondary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isInterested
                              ? Icons.people
                              : Icons.people_outline,
                          size: 16,
                          color: _isInterested
                              ? colorScheme.onSecondary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isInterested ? 'Interested' : "I'm Interested",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _isInterested
                                ? colorScheme.onSecondary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom CTA ────────────────────────────────────────────────────────────
  Widget _buildBottomCTA(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextButton(
            onPressed: () => navigateSmoothly(context, IdeaBiddingScreen(ideaTitle: widget.title)),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Interested? Start Bidding',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Star Rating ──────────────────────────────────────────────────────────────
class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    const Color goldStandard = Color(0xFFFBBF24);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half   = !filled && (i < rating);
        return Icon(
          half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
          size: 17,
          color: goldStandard,
        );
      }),
    );
  }
}

// ─── Pill Tag ─────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final IconData? icon;
  final String    label;
  final Color     bgColor;
  final Color     textColor;

  const _Pill({
    this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor),
          ),
        ],
      ),
    );
  }
}
