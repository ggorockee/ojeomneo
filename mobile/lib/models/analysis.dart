class Analysis {
  final String emotion;
  final List<String> keywords;
  final String mood;

  Analysis({
    required this.emotion,
    required this.keywords,
    required this.mood,
  });

  factory Analysis.fromJson(Map<String, dynamic> json) {
    return Analysis(
      emotion: json['emotion'] ?? '',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mood: json['mood'] ?? 'calm',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'keywords': keywords,
      'mood': mood,
    };
  }

  String get moodEmoji {
    switch (mood.toLowerCase()) {
      case 'bright':
        return '☀️';
      case 'calm':
        return '🌙';
      case 'dark':
        return '🌧️';
      default:
        return '🌤️';
    }
  }

  String get moodLabel {
    switch (mood.toLowerCase()) {
      case 'bright':
        return '밝음';
      case 'calm':
        return '차분함';
      case 'dark':
        return '어두움';
      default:
        return '중립';
    }
  }
}
