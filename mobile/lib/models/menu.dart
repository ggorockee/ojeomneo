class Menu {
  final int id;
  final String name;
  final String category;
  final String? imageUrl;
  final List<String> emotionTags;
  final List<String> situationTags;
  final List<String> attributeTags;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Menu({
    required this.id,
    required this.name,
    required this.category,
    this.imageUrl,
    this.emotionTags = const [],
    this.situationTags = const [],
    this.attributeTags = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'] ?? json['menu_id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['image_url'],
      emotionTags: _parseStringList(json['emotion_tags']),
      situationTags: _parseStringList(json['situation_tags']),
      attributeTags: _parseStringList(json['attribute_tags']),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'image_url': imageUrl,
      'emotion_tags': emotionTags,
      'situation_tags': situationTags,
      'attribute_tags': attributeTags,
      'is_active': isActive,
    };
  }

  List<String> get allTags => [...emotionTags, ...situationTags, ...attributeTags];
}
