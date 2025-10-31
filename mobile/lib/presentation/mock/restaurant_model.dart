class RestaurantModel {
  final String id;
  final String name;
  final String category;
  final double distance; // 미터 단위
  final double latitude;
  final double longitude;
  final double rating;
  final String? description;
  final String? phone;
  final String? address;
  final String? placeUrl;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.category,
    required this.distance,
    required this.latitude,
    required this.longitude,
    this.rating = 4.0,
    this.description,
    this.phone,
    this.address,
    this.placeUrl,
  });

  /// 카카오 로컬 API 응답을 RestaurantModel로 변환
  factory RestaurantModel.fromKakaoApi(Map<String, dynamic> json) {
    // 카테고리명 추출 (마지막 > 뒤의 내용만 사용)
    final categoryName = json['category_name'] as String? ?? '';
    final categoryParts = categoryName.split('>');
    final simplifiedCategory = categoryParts.isNotEmpty 
        ? categoryParts.last.trim() 
        : '음식점';

    // 거리 변환 (String -> double)
    final distanceStr = json['distance'] as String? ?? '0';
    final distance = double.tryParse(distanceStr) ?? 0.0;

    // 좌표 변환 (String -> double)
    final x = double.tryParse(json['x'] as String? ?? '0') ?? 0.0;
    final y = double.tryParse(json['y'] as String? ?? '0') ?? 0.0;

    return RestaurantModel(
      id: json['id'] as String? ?? '',
      name: json['place_name'] as String? ?? '이름 없음',
      category: simplifiedCategory,
      distance: distance,
      latitude: y,
      longitude: x,
      rating: 4.0 + (distance % 10) / 10, // 임시 평점 (거리 기반)
      phone: json['phone'] as String?,
      address: json['address_name'] as String?,
      placeUrl: json['place_url'] as String?,
    );
  }

  // 거리를 사람이 읽기 쉬운 형태로 변환
  String get distanceText {
    if (distance < 1000) {
      return '${distance.toInt()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }
}
