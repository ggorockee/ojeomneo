import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// 위치 상태 클래스
class LocationState {
  final Position? position;
  final LocationPermission permission;
  final bool isLoading;
  final String? errorMessage;

  const LocationState({
    this.position,
    required this.permission,
    this.isLoading = false,
    this.errorMessage,
  });

  /// 권한이 허용되었는지 확인
  bool get isGranted =>
      permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;

  /// 권한이 거부되었는지 확인
  bool get isDenied => permission == LocationPermission.denied;

  /// 권한이 영구적으로 거부되었는지 확인
  bool get isPermanentlyDenied =>
      permission == LocationPermission.deniedForever;

  /// 권한이 필요한 상태인지 확인
  bool get needsPermission => isDenied || isPermanentlyDenied;

  /// 상태 복사
  LocationState copyWith({
    Position? position,
    LocationPermission? permission,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LocationState(
      position: position ?? this.position,
      permission: permission ?? this.permission,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// 위치 노티파이어
class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    // 초기화 시 권한 확인
    _initializePermission();
    return const LocationState(
      permission: LocationPermission.denied,
    );
  }

  Future<void> _initializePermission() async {
    await checkPermission();
  }

  /// 권한 확인
  Future<void> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    print('🔍 [LocationProvider] checkPermission - 현재 상태: $permission');
    state = state.copyWith(permission: permission);
  }

  /// 권한 요청
  Future<LocationPermission> requestPermission() async {
    print('📱 [LocationProvider] requestPermission 시작');
    print('   요청 전 상태: ${await Geolocator.checkPermission()}');

    final permission = await Geolocator.requestPermission();

    print('   요청 후 상태: $permission');
    print('   isGranted: ${permission == LocationPermission.always || permission == LocationPermission.whileInUse}');
    print('   isDenied: ${permission == LocationPermission.denied}');
    print('   isPermanentlyDenied: ${permission == LocationPermission.deniedForever}');

    state = state.copyWith(permission: permission);

    // 권한 획득 시 자동으로 위치 정보 가져오기
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      await getCurrentPosition();
    }

    return permission;
  }

  /// 설정 앱 열기
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  /// 현재 위치 가져오기
  Future<void> getCurrentPosition() async {
    state = state.copyWith(isLoading: true);

    try {
      // 위치 서비스 활성화 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '위치 서비스를 활성화해주세요',
        );
        return;
      }

      // 위치 정보 획득
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      state = state.copyWith(
        position: position,
        isLoading: false,
        errorMessage: null,
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '위치 정보를 가져오는데 시간이 너무 오래 걸립니다',
      );
    } on LocationServiceDisabledException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '위치 서비스가 비활성화되어 있습니다',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '위치 정보를 가져올 수 없습니다: $e',
      );
    }
  }

  /// 앱 재진입 시 권한 재확인 (설정 앱에서 돌아왔을 때)
  Future<void> recheckPermissionOnResume() async {
    await checkPermission();

    // 권한이 허용되었고 위치 정보가 없으면 가져오기
    if (state.isGranted && state.position == null) {
      await getCurrentPosition();
    }
  }
}

/// Provider 선언
final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  () => LocationNotifier(),
);
