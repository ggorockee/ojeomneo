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

  void dispose() {
    _client.close();
  }
}
