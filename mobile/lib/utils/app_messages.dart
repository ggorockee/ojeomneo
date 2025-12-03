import 'package:flutter/foundation.dart';

/// 앱 메시지 관리 클래스
/// - 디버그 모드: 개발자용 상세 메시지
/// - 릴리즈 모드: 사용자 친화적 메시지 (Naver 스타일)
class AppMessages {
  // ===== 네트워크 에러 =====
  static String get networkError => kDebugMode
      ? '[DEV] 네트워크 연결 실패: 서버 응답 없음'
      : '일시적인 오류가 발생했어요.\n잠시 후 다시 시도해 주세요.';

  static String networkErrorWithCode(int statusCode) => kDebugMode
      ? '[DEV] HTTP 오류: $statusCode'
      : '요청을 처리하지 못했어요.\n잠시 후 다시 시도해 주세요.';

  static String get connectionTimeout => kDebugMode
      ? '[DEV] 연결 시간 초과: 서버 응답 지연'
      : '연결이 원활하지 않아요.\n네트워크 상태를 확인해 주세요.';

  // ===== API 에러 =====
  static String get apiError => kDebugMode
      ? '[DEV] API 호출 실패'
      : '서비스 이용에 불편을 드려 죄송해요.\n잠시 후 다시 시도해 주세요.';

  static String apiErrorWithMessage(String message) => kDebugMode
      ? '[DEV] API 에러: $message'
      : '요청을 처리하지 못했어요.\n잠시 후 다시 시도해 주세요.';

  // ===== 스케치 관련 =====
  static String get sketchEmpty => '그림을 그려주세요!';

  static String get sketchAnalyzing => '그림을 분석하고 있어요...';

  static String get sketchAnalyzeFailed => kDebugMode
      ? '[DEV] 스케치 분석 실패'
      : '그림 분석에 실패했어요.\n다시 시도해 주세요.';

  static String get imageCaptureFailed => kDebugMode
      ? '[DEV] 이미지 캡처 실패: Canvas 렌더링 오류'
      : '이미지 처리 중 오류가 발생했어요.\n다시 시도해 주세요.';

  // ===== 히스토리 관련 =====
  static String get historyLoadFailed => kDebugMode
      ? '[DEV] 히스토리 로드 실패'
      : '기록을 불러오지 못했어요.\n잠시 후 다시 시도해 주세요.';

  static String get historyEmpty => '아직 추천 기록이 없어요';

  static String get historyEmptyDescription => '그림을 그리고 메뉴 추천을 받아보세요!';

  // ===== 메뉴 관련 =====
  static String get menuLoadFailed => kDebugMode
      ? '[DEV] 메뉴 로드 실패'
      : '메뉴 정보를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요.';

  // ===== 일반 =====
  static String get unknownError => kDebugMode
      ? '[DEV] 알 수 없는 오류 발생'
      : '문제가 발생했어요.\n잠시 후 다시 시도해 주세요.';

  static String get pleaseWait => '잠시만 기다려주세요';

  static String get retry => '다시 시도';

  static String get confirm => '확인';

  static String get cancel => '취소';

  // ===== Rate Limiting =====
  static String get rateLimitExceeded => kDebugMode
      ? '[DEV] Rate Limit 초과: 일일 요청 한도 도달'
      : '오늘 추천 횟수를 모두 사용했어요.\n내일 다시 만나요!';

  // ===== 공유 관련 =====
  static String get shareFailed => kDebugMode
      ? '[DEV] 공유 실패'
      : '공유하기에 실패했어요.\n다시 시도해 주세요.';

  /// 에러 메시지 변환 (Exception → 사용자 메시지)
  static String fromException(dynamic error) {
    if (kDebugMode) {
      return '[DEV] Exception: ${error.toString()}';
    }
    return unknownError;
  }
}
