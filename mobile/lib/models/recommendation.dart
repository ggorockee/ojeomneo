class MenuRecommendation {
  final int menuId;
  final String name;
  final String category;
  final String? imageUrl;
  final String reason;
  final List<String> tags;

  MenuRecommendation({
    required this.menuId,
    required this.name,
    required this.category,
    this.imageUrl,
    required this.reason,
    this.tags = const [],
  });

  factory MenuRecommendation.fromJson(Map<String, dynamic> json) {
    return MenuRecommendation(
      menuId: json['menu_id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['image_url'],
      reason: json['reason'] ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_id': menuId,
      'name': name,
      'category': category,
      'image_url': imageUrl,
      'reason': reason,
      'tags': tags,
    };
  }
}

class Recommendation {
  final MenuRecommendation primary;
  final List<MenuRecommendation> alternatives;

  Recommendation({
    required this.primary,
    this.alternatives = const [],
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      primary: MenuRecommendation.fromJson(json['primary'] ?? {}),
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => MenuRecommendation.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': primary.toJson(),
      'alternatives': alternatives.map((e) => e.toJson()).toList(),
    };
  }
}
