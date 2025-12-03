import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_theme.dart';
import '../models/analysis.dart';
import '../models/sketch_result.dart';
import '../models/recommendation.dart';

class ResultScreen extends StatelessWidget {
  final SketchResult result;

  const ResultScreen({super.key, required this.result});

  void _shareResult(BuildContext context) {
    final primary = result.recommendation.primary;
    final text = '''
오점너가 추천하는 오늘의 메뉴

${primary.name}

"${primary.reason}"

#오점너 #오늘점심뭐먹지 #메뉴추천
''';

    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final primary = result.recommendation.primary;
    final alternatives = result.recommendation.alternatives;
    final analysis = result.analysis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('추천 결과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: '공유하기',
            onPressed: () => _shareResult(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Analysis section
              _AnalysisCard(analysis: analysis),
              const SizedBox(height: 24),

              // Primary recommendation
              Text(
                '오늘의 추천 메뉴',
                style: AppTheme.titleLarge.copyWith(
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _PrimaryMenuCard(menu: primary),
              const SizedBox(height: 24),

              // Alternative recommendations
              if (alternatives.isNotEmpty) ...[
                Text(
                  '이런 메뉴도 어때요?',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...alternatives.map(
                  (menu) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AlternativeMenuCard(menu: menu),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('다시 그리기'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _shareResult(context),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('공유하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final Analysis analysis;

  const _AnalysisCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primaryColor.withAlpha(26),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  analysis.moodEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  '그림에서 느껴지는 감정',
                  style: AppTheme.titleSmall.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              analysis.emotion,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.keywords.map((keyword) {
                return Chip(
                  label: Text(
                    keyword,
                    style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryColor.withAlpha(26),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryMenuCard extends StatelessWidget {
  final MenuRecommendation menu;

  const _PrimaryMenuCard({required this.menu});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: menu.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: menu.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.surfaceVariant,
                      child: const Icon(
                        Icons.restaurant_rounded,
                        size: 48,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.surfaceVariant,
                    child: const Icon(
                      Icons.restaurant_rounded,
                      size: 48,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getCategoryLabel(menu.category),
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Menu name
                Text(
                  menu.name,
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Recommendation reason
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant.withAlpha(77),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💬',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          menu.reason,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tags
                if (menu.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: menu.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.outlineColor.withAlpha(77),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '#$tag',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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

  const _AlternativeMenuCard({required this.menu});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: menu.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: menu.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.surfaceVariant,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.surfaceVariant,
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.surfaceVariant,
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        title: Text(
          menu.name,
          style: AppTheme.titleMedium,
        ),
        subtitle: Text(
          menu.reason,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
