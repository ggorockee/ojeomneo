import 'dart:math' show sin, cos, sqrt, atan2, pi;

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

  // Place Details API에서 가져오는 추가 정보
  final int? userRatingsTotal; // 평점 개수
  final String? website; // 웹사이트
  final String? internationalPhoneNumber; // 국제 전화번호
  final Map<String, dynamic>? openingHours; // 영업시간 정보
  final String? businessStatus; // 영업 상태 (OPERATIONAL, CLOSED_TEMPORARILY 등)
  final List<Map<String, dynamic>>? photos; // 사진 정보
  final List<Map<String, dynamic>>? reviews; // 리뷰 정보
  final int? priceLevel; // 가격 수준 (0-4)

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.category,
    required this.distance,
    required this.latitude,
    required this.longitude,
    this.rating = 0.0,
    this.description,
    this.phone,
    this.address,
    this.placeUrl,
    this.userRatingsTotal,
    this.website,
    this.internationalPhoneNumber,
    this.openingHours,
    this.businessStatus,
    this.photos,
    this.reviews,
    this.priceLevel,
  });

  /// Google Places API 응답을 RestaurantModel로 변환 (Nearby Search)
  factory RestaurantModel.fromGooglePlaces(
    Map<String, dynamic> json,
    double userLat,
    double userLng,
  ) {
    // 좌표 추출
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (location?['lng'] as num?)?.toDouble() ?? 0.0;

    // 거리 계산 (Haversine 공식)
    final distance = _calculateDistance(userLat, userLng, lat, lng);

    // 카테고리 추출 (types 배열에서)
    final types = (json['types'] as List<dynamic>?)?.cast<String>() ?? [];
    final category = _getCategoryFromTypes(types);

    // 평점 추출 (Google Places API 실제 평점)
    final rating = (json['rating'] as num?)?.toDouble() ?? 0.0;

    return RestaurantModel(
      id: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '이름 없음',
      category: category,
      distance: distance,
      latitude: lat,
      longitude: lng,
      rating: rating,
      phone: json['formatted_phone_number'] as String?,
      address: json['vicinity'] as String? ?? json['formatted_address'] as String?,
      placeUrl: json['url'] as String?,
    );
  }

  /// Google Place Details API 응답을 RestaurantModel로 변환
  factory RestaurantModel.fromPlaceDetails(
    Map<String, dynamic> json,
    double userLat,
    double userLng,
  ) {
    // 좌표 추출
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (location?['lng'] as num?)?.toDouble() ?? 0.0;

    // 거리 계산
    final distance = _calculateDistance(userLat, userLng, lat, lng);

    // 카테고리 추출
    final types = (json['types'] as List<dynamic>?)?.cast<String>() ?? [];
    final category = _getCategoryFromTypes(types);

    // 평점 정보
    final rating = (json['rating'] as num?)?.toDouble() ?? 0.0;
    final userRatingsTotal = json['user_ratings_total'] as int?;

    // 영업시간 정보
    final openingHours = json['opening_hours'] as Map<String, dynamic>?;

    // 사진 정보
    final photosJson = json['photos'] as List<dynamic>?;
    final photos = photosJson
        ?.map((photo) => photo as Map<String, dynamic>)
        .toList();

    // 리뷰 정보
    final reviewsJson = json['reviews'] as List<dynamic>?;
    final reviews = reviewsJson
        ?.map((review) => review as Map<String, dynamic>)
        .toList();

    return RestaurantModel(
      id: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '이름 없음',
      category: category,
      distance: distance,
      latitude: lat,
      longitude: lng,
      rating: rating,
      phone: json['formatted_phone_number'] as String?,
      address: json['formatted_address'] as String?,
      placeUrl: json['url'] as String?,
      userRatingsTotal: userRatingsTotal,
      website: json['website'] as String?,
      internationalPhoneNumber: json['international_phone_number'] as String?,
      openingHours: openingHours,
      businessStatus: json['business_status'] as String?,
      photos: photos,
      reviews: reviews,
      priceLevel: json['price_level'] as int?,
    );
  }

  /// 기존 RestaurantModel을 Place Details 정보로 업데이트
  RestaurantModel copyWithDetails({
    int? userRatingsTotal,
    String? website,
    String? internationalPhoneNumber,
    Map<String, dynamic>? openingHours,
    String? businessStatus,
    List<Map<String, dynamic>>? photos,
    List<Map<String, dynamic>>? reviews,
    int? priceLevel,
    String? phone,
    String? address,
  }) {
    return RestaurantModel(
      id: id,
      name: name,
      category: category,
      distance: distance,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      description: description,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      placeUrl: placeUrl,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      website: website ?? this.website,
      internationalPhoneNumber: internationalPhoneNumber ?? this.internationalPhoneNumber,
      openingHours: openingHours ?? this.openingHours,
      businessStatus: businessStatus ?? this.businessStatus,
      photos: photos ?? this.photos,
      reviews: reviews ?? this.reviews,
      priceLevel: priceLevel ?? this.priceLevel,
    );
  }

  /// types 배열에서 한국어 카테고리명 추출
  static String _getCategoryFromTypes(List<String> types) {
    const typeMap = {
      'restaurant': '음식점',
      'cafe': '카페',
      'bakery': '베이커리',
      'bar': '술집',
      'meal_takeaway': '테이크아웃',
      'meal_delivery': '배달',
      'food': '음식점',
    };

    for (final type in types) {
      if (typeMap.containsKey(type)) {
        return typeMap[type]!;
      }
    }

    return '음식점';
  }

  /// Haversine 공식으로 두 좌표 사이의 거리 계산 (미터)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000; // 지구 반경 (미터)

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degree) => degree * pi / 180;

  // 거리를 사람이 읽기 쉬운 형태로 변환
  String get distanceText {
    if (distance < 1000) {
      return '${distance.toInt()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }
}
