import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/sketch_result.dart';
import '../utils/app_messages.dart';
import 'api_service.dart';
import 'ads/ad_service.dart';

enum SketchState { idle, drawing, analyzing, success, error }

/// 스트로크 데이터 (점 목록 + 색상 + 굵기)
class StrokeData {
  final List<Offset> points;
  final Color color;
  final double width;

  StrokeData({
    required this.points,
    required this.color,
    required this.width,
  });

  StrokeData copyWith({
    List<Offset>? points,
    Color? color,
    double? width,
  }) {
    return StrokeData(
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
    );
  }
}

class SketchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  SketchState _state = SketchState.idle;
  SketchResult? _result;
  String? _errorMessage;
  List<SketchHistory> _history = [];
  bool _isLoadingHistory = false;
  int _historyPage = 1;
  bool _hasMoreHistory = true;

  // Drawing state - 각 스트로크별로 색상/굵기 저장
  List<StrokeData> _strokes = [];
  List<Offset> _currentStrokePoints = [];
  Color _currentColor = Colors.black;
  double _currentWidth = 4.0;

  // Getters
  SketchState get state => _state;
  SketchResult? get result => _result;
  String? get errorMessage => _errorMessage;
  List<SketchHistory> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get hasMoreHistory => _hasMoreHistory;

  List<StrokeData> get strokes => _strokes;
  List<Offset> get currentStrokePoints => _currentStrokePoints;
  Color get currentColor => _currentColor;
  double get currentWidth => _currentWidth;
  bool get hasDrawing => _strokes.isNotEmpty || _currentStrokePoints.isNotEmpty;

  void setStrokeColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _currentWidth = width;
    notifyListeners();
  }

  void startStroke(Offset point) {
    _currentStrokePoints = [point];
    _state = SketchState.drawing;
    notifyListeners();
  }

  void addPoint(Offset point) {
    _currentStrokePoints.add(point);
    notifyListeners();
  }

  void endStroke() {
    if (_currentStrokePoints.isNotEmpty) {
      _strokes.add(StrokeData(
        points: List.from(_currentStrokePoints),
        color: _currentColor,
        width: _currentWidth,
      ));
      _currentStrokePoints = [];
    }
    notifyListeners();
  }

  void clearCanvas() {
    _strokes = [];
    _currentStrokePoints = [];
    _state = SketchState.idle;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  void undoLastStroke() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  Future<Uint8List?> captureCanvas(Size size) async {
    if (_strokes.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw all strokes with their individual colors and widths
    for (final stroke in _strokes) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  Future<void> analyzeSketch(Uint8List imageBytes, {String? text}) async {
    _state = SketchState.analyzing;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _apiService.analyzeSketch(
        imageBytes: imageBytes,
        text: text,
      );
      _state = SketchState.success;

      // 분석 완료 후 전면광고 표시 (2회 분석마다)
      await AdService().showInterstitialAfterAnalysis();
    } catch (e) {
      _errorMessage = AppMessages.fromException(e);
      _state = SketchState.error;
    }

    notifyListeners();
  }

  Future<void> loadHistory({bool refresh = false}) async {
    if (_isLoadingHistory) return;
    if (!refresh && !_hasMoreHistory) return;

    if (refresh) {
      _historyPage = 1;
      _hasMoreHistory = true;
    }

    _isLoadingHistory = true;
    notifyListeners();

    try {
      final items = await _apiService.getHistory(page: _historyPage);

      if (refresh) {
        _history = items;
      } else {
        _history.addAll(items);
      }

      if (items.length < 10) {
        _hasMoreHistory = false;
      } else {
        _historyPage++;
      }
    } catch (e) {
      _errorMessage = AppMessages.historyLoadFailed;
    }

    _isLoadingHistory = false;
    notifyListeners();
  }

  void resetState() {
    _state = SketchState.idle;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }
}
