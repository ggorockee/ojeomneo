import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../models/sketch_result.dart';
import '../services/sketch_provider.dart';
import '../utils/app_messages.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SketchProvider>().loadHistory(refresh: true);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SketchProvider>().loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '히스토리',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.onSurface,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<SketchProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingHistory && provider.history.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          if (provider.history.isEmpty) {
            return _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadHistory(refresh: true),
            color: AppTheme.primaryColor,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: provider.history.length +
                  (provider.hasMoreHistory ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= provider.history.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(
                    history: provider.history[index],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 80,
              color: AppTheme.textDisabled,
            ),
            const SizedBox(height: 24),
            Text(
              AppMessages.historyEmpty,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppMessages.historyEmptyDescription,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.primaryButtonShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.brush_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '그림 그리러 가기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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

class _HistoryCard extends StatelessWidget {
  final SketchHistory history;

  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final analysis = history.analysis;
    final recommendation = history.recommendation;
    final primaryMenu = recommendation?.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    analysis?.moodEmoji ?? '🍽️',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  if (primaryMenu != null)
                    Text(
                      primaryMenu.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                ],
              ),
              Text(
                _formatDate(history.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Emotion
          if (analysis != null)
            Text(
              analysis.emotion,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.onSurface,
              ),
            ),
          const SizedBox(height: 8),

          // Keywords
          if (analysis != null && analysis.keywords.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: analysis.keywords.map((keyword) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    keyword,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),

          // Recommendation reason
          if (primaryMenu != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withAlpha(128),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                primaryMenu.reason,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}분 전';
      }
      return '${diff.inHours}시간 전';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
