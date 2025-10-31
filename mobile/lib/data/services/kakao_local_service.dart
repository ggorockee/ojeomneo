import 'package:dio/dio.dart';

/// 카카오 로컬 API 서비스
class KakaoLocalService {
  static const String _baseUrl = 'https://dapi.kakao.com/v2/local';
  static const String _restApiKey = 'b6bfc53cd0bef594351fe1efa4bb9849';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Authorization': 'KakaoAK $_restApiKey',
      },
    ),
  );

  /// 카테고리로 장소 검색
  /// 
  /// [categoryGroupCode] - 카테고리 그룹 코드 (FD6: 음식점, CE7: 카페 등)
  /// [x] - 중심 좌표 X (경도)
  /// [y] - 중심 좌표 Y (위도)
  /// [radius] - 반경 (미터, 최대 20000)
  /// [page] - 페이지 번호 (1~45)
  /// [size] - 페이지당 결과 수 (1~15)
  Future<Map<String, dynamic>> searchByCategory({
    required String categoryGroupCode,
    required double x,
    required double y,
    int radius = 2000,
    int page = 1,
    int size = 15,
  }) async {
    try {
      final response = await _dio.get(
        '/search/category.json',
        queryParameters: {
          'category_group_code': categoryGroupCode,
          'x': x.toString(),
          'y': y.toString(),
          'radius': radius,
          'page': page,
          'size': size,
          'sort': 'distance', // 거리순 정렬
        },
      );

      return response.data;
    } catch (e) {
      print('❌ 카카오 로컬 API 에러: $e');
      rethrow;
    }
  }

  /// 키워드로 장소 검색
  /// 
  /// [query] - 검색 키워드
  /// [x] - 중심 좌표 X (경도)
  /// [y] - 중심 좌표 Y (위도)
  /// [radius] - 반경 (미터, 최대 20000)
  /// [categoryGroupCode] - 카테고리 필터 (선택)
  Future<Map<String, dynamic>> searchByKeyword({
    required String query,
    required double x,
    required double y,
    int radius = 2000,
    String? categoryGroupCode,
    int page = 1,
    int size = 15,
  }) async {
    try {
      final queryParams = {
        'query': query,
        'x': x.toString(),
        'y': y.toString(),
        'radius': radius,
        'page': page,
        'size': size,
        'sort': 'distance',
      };

      if (categoryGroupCode != null) {
        queryParams['category_group_code'] = categoryGroupCode;
      }

      final response = await _dio.get(
        '/search/keyword.json',
        queryParameters: queryParams,
      );

      return response.data;
    } catch (e) {
      print('❌ 카카오 키워드 검색 API 에러: $e');
      rethrow;
    }
  }
}


