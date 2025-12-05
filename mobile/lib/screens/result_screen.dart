import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_theme.dart';
import '../models/sketch_result.dart';
import '../models/recommendation.dart';

class ResultScreen extends StatefulWidget {
  final SketchResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _selectedCardIndex = 0;

  List<MenuRecommendation> get _allMenus {
    final list = <MenuRecommendation>[widget.result.recommendation.primary];
    list.addAll(widget.result.recommendation.alternatives);
    return list;
  }

  MenuRecommendation get _selectedMenu => _allMenus[_selectedCardIndex];

  void _shareResult() {
    final menu = _selectedMenu;
    final text = '''
오점너가 추천하는 오늘의 메뉴

${menu.name}

"${menu.reason}"

#오점너 #오늘점심뭐먹지 #메뉴추천
''';

    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final alternatives = widget.result.recommendation.alternatives;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main card
                    _PrimaryMenuCard(menu: _selectedMenu),
                    const SizedBox(height: 32),

                    // Alternative recommendations
                    if (alternatives.isNotEmpty) ...[
                      const Text(
                        '이런 메뉴도 어때요?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._allMenus
                          .asMap()
                          .entries
                          .where((e) => e.key != _selectedCardIndex)
                          .take(2)
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AlternativeMenuCard(
                                menu: entry.value,
                                onTap: () {
                                  setState(() {
                                    _selectedCardIndex = entry.key;
                                  });
                                },
                              ),
                            ),
                          ),
                    ],
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom fixed buttons
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.onSurface,
              size: 22,
            ),
          ),
          const Text(
            '추천 결과',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppTheme.onSurface,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppTheme.surfaceColor.withAlpha(51),
            AppTheme.surfaceColor,
          ],
          stops: const [0.0, 0.2, 0.4],
        ),
      ),
      child: Row(
        children: [
          // Retry button
          Expanded(
            child: _ActionButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: Icons.refresh_rounded,
              label: '다시 추천',
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 12),

          // Share button
          Expanded(
            child: _ActionButton(
              onPressed: _shareResult,
              icon: Icons.share_rounded,
              label: '공유하기',
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryMenuCard extends StatelessWidget {
  final MenuRecommendation menu;

  const _PrimaryMenuCard({required this.menu});

  bool get _hasValidImage =>
      menu.imageUrl != null && menu.imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with 4:3 aspect ratio
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: _getCategoryColor(menu.category).withAlpha(51),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _hasValidImage
                  ? CachedNetworkImage(
                      imageUrl: menu.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(),
                      errorWidget: (context, url, error) =>
                          _buildEmojiPlaceholder(),
                    )
                  : _buildEmojiPlaceholder(),
            ),
          ),
          const SizedBox(height: 20),

          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.outlineColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getCategoryLabel(menu.category),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Menu name
          Text(
            menu.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Recommendation reason
          Text(
            menu.reason,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 20),

          // Tags
          if (menu.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: menu.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF444444),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.surfaceVariant,
      child: const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiPlaceholder() {
    return Center(
      child: Text(
        _getCategoryEmoji(menu.category),
        style: const TextStyle(fontSize: 80),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'korean':
        return const Color(0xFFFFF5F0);
      case 'japanese':
        return const Color(0xFFFFF8F0);
      case 'chinese':
        return const Color(0xFFFFF0F0);
      case 'western':
        return const Color(0xFFF5F0FF);
      case 'asian':
        return const Color(0xFFF0FFF5);
      default:
        return AppTheme.surfaceVariant;
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'korean':
        return '🍚';
      case 'japanese':
        return '🍜';
      case 'chinese':
        return '🥟';
      case 'western':
        return '🍝';
      case 'asian':
        return '🍲';
      case 'snack':
        return '🍢';
      case 'cafe':
        return '☕';
      default:
        return '🍽️';
    }
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'korean':
        return '한식';
      case 'chinese':
        return '중식';
      case 'japanese':
        return '일식';
      case 'western':
        return '양식';
      case 'asian':
        return '아시안';
      case 'snack':
        return '분식';
      case 'cafe':
        return '카페';
      default:
        return '기타';
    }
  }
}

class _AlternativeMenuCard extends StatelessWidget {
  final MenuRecommendation menu;
  final VoidCallback onTap;

  const _AlternativeMenuCard({
    required this.menu,
    required this.onTap,
  });

  bool get _hasValidImage =>
      menu.imageUrl != null && menu.imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getCategoryColor(menu.category),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: _hasValidImage
                  ? CachedNetworkImage(
                      imageUrl: menu.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.surfaceVariant,
                      ),
                      errorWidget: (context, url, error) =>
                          _buildSmallPlaceholder(),
                    )
                  : _buildSmallPlaceholder(),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCategoryLabel(menu.category),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    menu.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textDisabled,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallPlaceholder() {
    return Center(
      child: Text(
        _getCategoryEmoji(menu.category),
        style: const TextStyle(fontSize: 28),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'korean':
        return const Color(0xFFFFF5F0);
      case 'japanese':
        return const Color(0xFFFFF8F0);
      case 'chinese':
        return const Color(0xFFFFF0F0);
      case 'western':
        return const Color(0xFFF5F0FF);
      case 'asian':
        return const Color(0xFFF0FFF5);
      default:
        return AppTheme.surfaceVariant;
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'korean':
        return '🍚';
      case 'japanese':
        return '🍜';
      case 'chinese':
        return '🥟';
      case 'western':
        return '🍝';
      case 'asian':
        return '🍲';
      default:
        return '🍽️';
    }
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'korean':
        return '한식';
      case 'chinese':
        return '중식';
      case 'japanese':
        return '일식';
      case 'western':
        return '양식';
      case 'asian':
        return '아시안';
      case 'snack':
        return '분식';
      case 'cafe':
        return '카페';
      default:
        return '기타';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.primaryButtonShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.toolButtonInactive,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.onSurface, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
