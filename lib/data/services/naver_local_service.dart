import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 네이버 지역 검색 API 서비스
class NaverLocalService {
  static const String _baseUrl = 'https://openapi.naver.com/v1';
  static final String _clientId = dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';
  static final String _clientSecret = dotenv.env['NAVER_CLIENT_SECRET'] ?? '';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'X-Naver-Client-Id': _clientId,
        'X-Naver-Client-Secret': _clientSecret,
      },
    ),
  );

  /// 지역 검색 (Local Search)
  ///
  /// [query] - 검색어 (필수)
  /// [latitude] - 중심 좌표 위도 (선택, 정확도 향상)
  /// [longitude] - 중심 좌표 경도 (선택, 정확도 향상)
  /// [display] - 한 번에 표시할 검색 결과 개수(기본값: 5, 최댓값: 5)
  /// [start] - 검색 시작 위치 (기본값: 1, 최댓값: 1)
  /// [sort] - 정렬 옵션 (random: 정확도순, comment: 업체 및 기관 리뷰 개수순)
  Future<Map<String, dynamic>> searchLocal({
    required String query,
    double? latitude,
    double? longitude,
    int display = 5,
    int start = 1,
    String sort = 'random',
  }) async {
    try {
      final queryParams = {
        'query': query,
        'display': display.toString(),
        'start': start.toString(),
        'sort': sort,
      };

      print('🔍 네이버 지역 검색 API 요청: $queryParams');

      final response = await _dio.get(
        '/search/local.json',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      print('✅ 네이버 지역 검색 API 응답: ${items.length}개');

      return data;
    } catch (e) {
      print('❌ 네이버 지역 검색 API 에러: $e');
      rethrow;
    }
  }

  /// 주변 맛집 검색
  ///
  /// [latitude] - 중심 좌표 위도
  /// [longitude] - 중심 좌표 경도
  /// [category] - 카테고리 (전체, 음식점, 카페, 베이커리, 술집)
  /// [keyword] - 추가 검색 키워드 (선택)
  Future<Map<String, dynamic>> searchNearbyRestaurants({
    required double latitude,
    required double longitude,
    String category = '음식점',
    String? keyword,
  }) async {
    try {
      // 카테고리별 검색어 매핑
      String searchQuery;
      if (keyword != null && keyword.isNotEmpty) {
        searchQuery = '$keyword $category';
      } else {
        searchQuery = category;
      }

      print('🍽️ 주변 $searchQuery 검색 (위치: $latitude, $longitude)');

      final response = await searchLocal(
        query: searchQuery,
        latitude: latitude,
        longitude: longitude,
        display: 5,
        sort: 'random', // 정확도순
      );

      return response;
    } catch (e) {
      print('❌ 주변 맛집 검색 에러: $e');
      rethrow;
    }
  }

  /// 텍스트 검색
  ///
  /// [query] - 검색어
  /// [latitude] - 중심 좌표 위도 (선택)
  /// [longitude] - 중심 좌표 경도 (선택)
  Future<Map<String, dynamic>> textSearch({
    required String query,
    double? latitude,
    double? longitude,
  }) async {
    try {
      return await searchLocal(
        query: query,
        latitude: latitude,
        longitude: longitude,
        display: 5,
      );
    } catch (e) {
      print('❌ 텍스트 검색 에러: $e');
      rethrow;
    }
  }

  /// 네이버 지역 검색 결과를 앱 모델로 변환
  ///
  /// 네이버 API 응답 형식:
  /// - title: 업체명 (HTML 태그 포함 가능)
  /// - link: 네이버 업체 페이지 URL
  /// - category: 업종 분류
  /// - description: 업체 설명
  /// - telephone: 전화번호
  /// - address: 지번 주소
  /// - roadAddress: 도로명 주소
  /// - mapx: X 좌표 (카텍좌표계)
  /// - mapy: Y 좌표 (카텍좌표계)
  Map<String, dynamic> convertToAppModel(Map<String, dynamic> naverPlace) {
    // HTML 태그 제거
    String cleanTitle(String title) {
      return title
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&quot;', '"')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>');
    }

    // 카텍 좌표를 WGS84 좌표로 변환 (간단한 근사 변환)
    double convertMapX(String mapx) {
      final x = double.parse(mapx);
      return x / 1000000.0;
    }

    double convertMapY(String mapy) {
      final y = double.parse(mapy);
      return y / 1000000.0;
    }

    return {
      'place_id': naverPlace['link'] ?? '', // 네이버 링크를 ID로 사용
      'name': cleanTitle(naverPlace['title'] ?? ''),
      'vicinity': naverPlace['roadAddress'] ?? naverPlace['address'] ?? '',
      'rating': 0.0, // 네이버 지역 검색 API는 평점 미제공
      'user_ratings_total': 0, // 네이버 지역 검색 API는 리뷰 수 미제공
      'geometry': {
        'location': {
          'lat': convertMapY(naverPlace['mapy'] ?? '0'),
          'lng': convertMapX(naverPlace['mapx'] ?? '0'),
        }
      },
      'types': [naverPlace['category'] ?? ''],
      'photos': [], // 네이버 지역 검색 API는 사진 미제공
      'business_status': 'OPERATIONAL',
      'phone': naverPlace['telephone'] ?? '',
      'website': naverPlace['link'] ?? '',
      'category': naverPlace['category'] ?? '',
    };
  }
}
