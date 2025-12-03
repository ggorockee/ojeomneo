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
    return SketchHistory(
      id: json['id'] ?? '',
      imagePath: json['image_path'],
      inputText: json['input_text'],
      analysis: json['analysis_result'] != null
          ? Analysis.fromJson(json['analysis_result'])
          : null,
      recommendation: json['recommendation'] != null
          ? Recommendation.fromJson(json['recommendation'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
