import 'analysis.dart';
import 'recommendation.dart';

class SketchResult {
  final String sketchId;
  final Analysis analysis;
  final Recommendation recommendation;
  final DateTime createdAt;

  SketchResult({
    required this.sketchId,
    required this.analysis,
    required this.recommendation,
    required this.createdAt,
  });

  factory SketchResult.fromJson(Map<String, dynamic> json) {
    return SketchResult(
      sketchId: json['sketch_id'] ?? '',
      analysis: Analysis.fromJson(json['analysis'] ?? {}),
      recommendation: Recommendation.fromJson(json['recommendation'] ?? {}),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sketch_id': sketchId,
      'analysis': analysis.toJson(),
      'recommendation': recommendation.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SketchHistory {
  final String id;
  final String? imagePath;
  final String? inputText;
  final Analysis? analysis;
  final Recommendation? recommendation;
  final DateTime createdAt;

  SketchHistory({
    required this.id,
    this.imagePath,
    this.inputText,
    this.analysis,
    this.recommendation,
    required this.createdAt,
  });

  factory SketchHistory.fromJson(Map<String, dynamic> json) {
    // 서버에서 'recommendations' 배열로 반환됨 (각 항목에 menu 관계 포함)
    Recommendation? recommendation;

    if (json['recommendation'] != null) {
      // 새로운 분석 결과 형식 (primary/alternatives)
      recommendation = Recommendation.fromJson(json['recommendation']);
    } else if (json['recommendations'] != null) {
      // 히스토리 API 형식 (recommendations 배열 + menu 관계)
      final recommendations = json['recommendations'] as List<dynamic>? ?? [];
      if (recommendations.isNotEmpty) {
        // rank로 정렬하여 primary(rank=1)와 alternatives 분리
        final sortedRecs = List<Map<String, dynamic>>.from(
          recommendations.map((e) => e as Map<String, dynamic>),
        )..sort((a, b) => (a['rank'] ?? 1).compareTo(b['rank'] ?? 1));

        // primary (rank=1)
        final primaryRec = sortedRecs.first;
        final primaryMenu = primaryRec['menu'] as Map<String, dynamic>?;

        // 이미지 URL 처리: 빈 문자열이 아닌 경우에만 설정
        final primaryImageUrl = primaryMenu?['image_url'];
        final primaryTags = <String>[];
        if (primaryMenu != null) {
          // 모든 태그 타입을 합쳐서 tags에 추가
          final emotionTags = (primaryMenu['emotion_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
          final situationTags = (primaryMenu['situation_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
          final attributeTags = (primaryMenu['attribute_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
          primaryTags.addAll(emotionTags);
          primaryTags.addAll(situationTags);
          primaryTags.addAll(attributeTags);
        }

        final primary = MenuRecommendation(
          menuId: primaryRec['menu_id'] ?? primaryMenu?['id'] ?? 0,
          name: primaryMenu?['name'] ?? '',
          category: primaryMenu?['category'] ?? '',
          imageUrl: (primaryImageUrl != null && primaryImageUrl.toString().isNotEmpty)
              ? primaryImageUrl.toString()
              : null,
          reason: primaryRec['reason'] ?? '',
          tags: primaryTags,
        );

        // alternatives (rank > 1)
        final alternatives = sortedRecs.skip(1).map((rec) {
          final menu = rec['menu'] as Map<String, dynamic>?;
          final altImageUrl = menu?['image_url'];
          final altTags = <String>[];
          if (menu != null) {
            // 모든 태그 타입을 합쳐서 tags에 추가
            final emotionTags = (menu['emotion_tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ?? [];
            final situationTags = (menu['situation_tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ?? [];
            final attributeTags = (menu['attribute_tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ?? [];
            altTags.addAll(emotionTags);
            altTags.addAll(situationTags);
            altTags.addAll(attributeTags);
          }
          return MenuRecommendation(
            menuId: rec['menu_id'] ?? menu?['id'] ?? 0,
            name: menu?['name'] ?? '',
            category: menu?['category'] ?? '',
            imageUrl: (altImageUrl != null && altImageUrl.toString().isNotEmpty)
                ? altImageUrl.toString()
                : null,
            reason: rec['reason'] ?? '',
            tags: altTags,
          );
        }).toList();

        recommendation = Recommendation(
          primary: primary,
          alternatives: alternatives,
        );
      }
    }

    return SketchHistory(
      id: json['id'] ?? '',
      imagePath: json['image_path'],
      inputText: json['input_text'],
      analysis: json['analysis_result'] != null
          ? Analysis.fromJson(json['analysis_result'])
          : null,
      recommendation: recommendation,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
