import 'package:dio/dio.dart';

/// Google Places API 서비스
class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _apiKey = 'AIzaSyAErzB1kQHvit41AK0mXf9T5iBgiN5siJI';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// 주변 장소 검색 (Nearby Search)
  ///
  /// [latitude] - 중심 좌표 위도
  /// [longitude] - 중심 좌표 경도
  /// [radius] - 반경 (미터, 최대 50000)
  /// [type] - 장소 타입 (restaurant, cafe 등)
  /// [keyword] - 검색 키워드 (선택)
  Future<Map<String, dynamic>> searchNearby({
    required double latitude,
    required double longitude,
    int radius = 2000,
    String type = 'restaurant',
    String? keyword,
    String? pageToken,
  }) async {
    try {
      final queryParams = {
        'location': '$latitude,$longitude',
        'radius': radius.toString(),
        'type': type,
        'key': _apiKey,
        'language': 'ko', // 한국어 결과
      };

      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      if (pageToken != null) {
        queryParams['pagetoken'] = pageToken;
      }

      print('🔍 Google Places API 요청: $queryParams');

      final response = await _dio.get(
        '/nearbysearch/json',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      print('✅ Google Places API 응답: ${data['results']?.length ?? 0}개');

      return data;
    } catch (e) {
      print('❌ Google Places API 에러: $e');
      rethrow;
    }
  }

  /// 장소 상세 정보 조회
  ///
  /// [placeId] - Google Place ID
  Future<Map<String, dynamic>> getPlaceDetails({
    required String placeId,
  }) async {
    try {
      final response = await _dio.get(
        '/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'language': 'ko',
          'fields': 'name,rating,formatted_phone_number,formatted_address,geometry,types,photos,reviews',
        },
      );

      return response.data;
    } catch (e) {
      print('❌ Google Places Details API 에러: $e');
      rethrow;
    }
  }

  /// 텍스트 검색
  ///
  /// [query] - 검색어
  /// [latitude] - 중심 좌표 위도 (선택)
  /// [longitude] - 중심 좌표 경도 (선택)
  /// [radius] - 반경 (미터)
  Future<Map<String, dynamic>> textSearch({
    required String query,
    double? latitude,
    double? longitude,
    int radius = 5000,
  }) async {
    try {
      final queryParams = {
        'query': query,
        'key': _apiKey,
        'language': 'ko',
      };

      if (latitude != null && longitude != null) {
        queryParams['location'] = '$latitude,$longitude';
        queryParams['radius'] = radius.toString();
      }

      final response = await _dio.get(
        '/textsearch/json',
        queryParameters: queryParams,
      );

      return response.data;
    } catch (e) {
      print('❌ Google Places Text Search API 에러: $e');
      rethrow;
    }
  }
}
