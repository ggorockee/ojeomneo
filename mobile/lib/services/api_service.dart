import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/menu.dart';
import '../models/sketch_result.dart';
import '../utils/app_messages.dart';
import '../utils/device_id.dart';

// 디버그 로그 헬퍼
void _log(String message) {
  if (kDebugMode) {
    debugPrint('[API] $message');
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<SketchResult> analyzeSketch({
    required Uint8List imageBytes,
    String? text,
  }) async {
    final deviceId = await DeviceIdUtil.getDeviceId();
    final url = AppConfig.sketchAnalyzeUrl;

    _log('=== analyzeSketch 시작 ===');
    _log('URL: $url');
    _log('Device ID: $deviceId');
    _log('Image size: ${imageBytes.length} bytes');
    _log('Text: $text');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(url),
    );

    request.fields['device_id'] = deviceId;
    if (text != null && text.isNotEmpty) {
      request.fields['text'] = text;
    }

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'sketch.png',
    ));

    try {
      _log('요청 전송 중...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _log('응답 수신: ${response.statusCode}');
      _log('응답 Body: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          _log('성공! 파싱 중...');
          final result = SketchResult.fromJson(json['data']);
          _log('파싱 완료: ${result.sketchId}');
          return result;
        }
        _log('API 실패: ${json['message']}');
        throw ApiException(AppMessages.apiErrorWithMessage(json['message'] ?? ''));
      }

      if (response.statusCode == 429) {
        _log('Rate Limit 초과');
        throw ApiException(AppMessages.rateLimitExceeded, statusCode: 429);
      }

      _log('HTTP 에러: ${response.statusCode}');
      throw ApiException(
        AppMessages.networkErrorWithCode(response.statusCode),
        statusCode: response.statusCode,
      );
    } catch (e, stackTrace) {
      _log('예외 발생: $e');
      _log('Stack trace: $stackTrace');
      if (e is ApiException) rethrow;
      throw ApiException(AppMessages.networkError);
    }
  }

  Future<List<SketchHistory>> getHistory({
    int page = 1,
    int limit = 10,
  }) async {
    final deviceId = await DeviceIdUtil.getDeviceId();

    try {
      final response = await _client.get(
        Uri.parse(
          '${AppConfig.sketchHistoryUrl}?device_id=$deviceId&page=$page&limit=$limit',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        _log('History API Response: ${response.body.length > 1000 ? response.body.substring(0, 1000) : response.body}');
        if (json['success'] == true) {
          final items = json['data']['items'] as List<dynamic>? ?? [];
          return items.map((e) => SketchHistory.fromJson(e)).toList();
        }
        throw ApiException(AppMessages.apiErrorWithMessage(json['message'] ?? ''));
      }

      throw ApiException(
        AppMessages.networkErrorWithCode(response.statusCode),
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(AppMessages.historyLoadFailed);
    }
  }

  Future<List<Menu>> getMenus({
    String? category,
    String? tag,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category,
        if (tag != null) 'tag': tag,
      };

      final uri = Uri.parse(AppConfig.menusUrl).replace(
        queryParameters: queryParams,
      );

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final items = json['data']['items'] as List<dynamic>? ?? [];
          return items.map((e) => Menu.fromJson(e)).toList();
        }
        throw ApiException(AppMessages.apiErrorWithMessage(json['message'] ?? ''));
      }

      throw ApiException(
        AppMessages.networkErrorWithCode(response.statusCode),
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(AppMessages.menuLoadFailed);
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _client.get(
        Uri.parse(AppConfig.menuCategoriesUrl),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final categories = json['data']['categories'] as List<dynamic>? ?? [];
          return categories.map((e) => e.toString()).toList();
        }
        throw ApiException(AppMessages.apiErrorWithMessage(json['message'] ?? ''));
      }

      throw ApiException(
        AppMessages.networkErrorWithCode(response.statusCode),
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(AppMessages.menuLoadFailed);
    }
  }

  /// SNS 로그인 API 호출
  /// 
  /// [provider] - 'google', 'apple', 'kakao'
  /// [token] - Google은 id_token (Firebase ID Token), Apple/Kakao는 access_token
  Future<Map<String, dynamic>> postSNSLogin({
    required String provider,
    required String token,
  }) async {
    final url = _getAuthUrl(provider);
    _log('=== postSNSLogin 시작 ===');
    _log('Provider: $provider');
    _log('URL: $url');

    try {
      // Request body 구성
      final Map<String, dynamic> body;
      if (provider == 'google') {
        body = {'id_token': token};
      } else {
        // Apple은 identity_token, Kakao는 access_token
        final fieldName = provider == 'apple' ? 'identity_token' : 'access_token';
        body = {fieldName: token};
      }

      _log('Request body: ${body.keys}');

      final response = await _client.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      );

      _log('응답 수신: ${response.statusCode}');
      _log('응답 Body: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          _log('SNS 로그인 성공');
          return jsonData['data'] as Map<String, dynamic>;
        }
        final errorMsg = jsonData['error'] as String? ?? '로그인에 실패했습니다.';
        _log('API 실패: $errorMsg');
        throw ApiException(errorMsg);
      }

      // 에러 응답 파싱 시도
      try {
        final jsonData = jsonDecode(response.body);
        final errorMsg = jsonData['error'] as String? ?? '로그인에 실패했습니다.';
        throw ApiException(errorMsg, statusCode: response.statusCode);
      } catch (_) {
        throw ApiException(
          AppMessages.networkErrorWithCode(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      _log('예외 발생: $e');
      if (e is ApiException) rethrow;
      throw ApiException('로그인 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 인증 엔드포인트 URL 가져오기
  String _getAuthUrl(String provider) {
    switch (provider) {
      case 'google':
        return AppConfig.googleLoginUrl;
      case 'apple':
        return AppConfig.appleLoginUrl;
      case 'kakao':
        return AppConfig.kakaoLoginUrl;
      default:
        throw ArgumentError('Unknown provider: $provider');
    }
  }

  void dispose() {
    _client.close();
  }
}
