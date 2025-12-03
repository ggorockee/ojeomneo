import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/menu.dart';
import '../models/sketch_result.dart';
import '../utils/app_messages.dart';
import '../utils/device_id.dart';

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

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppConfig.sketchAnalyzeUrl),
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
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          return SketchResult.fromJson(json['data']);
        }
        throw ApiException(AppMessages.apiErrorWithMessage(json['message'] ?? ''));
      }

      if (response.statusCode == 429) {
        throw ApiException(AppMessages.rateLimitExceeded, statusCode: 429);
      }

      throw ApiException(
        AppMessages.networkErrorWithCode(response.statusCode),
        statusCode: response.statusCode,
      );
    } catch (e) {
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
