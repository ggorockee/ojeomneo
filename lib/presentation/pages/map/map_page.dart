import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/kakao_local_service.dart';
import '../../mock/restaurant_model.dart';
import '../../providers/location_provider.dart';
import '../../widgets/location_permission_dialog.dart';

class MapPage extends ConsumerStatefulWidget {
  final String? category; // 카테고리 필터링용

  const MapPage({super.key, this.category});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> with WidgetsBindingObserver {
  late KakaoMapController _mapController;
  List<RestaurantModel> _restaurants = []; // 전체 검색된 식당 목록
  List<RestaurantModel> _visibleRestaurants = []; // 현재 화면에 보이는 식당 목록
  RestaurantModel? _selectedRestaurant; // 선택된 식당 (핀 클릭 시)
  bool _isLoadingLocation = false;
  bool _dialogShown = false; // 다이얼로그 중복 표시 방지
  bool _isMapReady = false; // 지도 준비 상태
  final Map<String, Poi> _markers = {}; // 지도에 추가된 마커 목록 (key: restaurant id)
  double _panelPosition = 0.0; // 슬라이딩 패널 위치 (0.0 ~ 1.0)
  
  // 카카오 로컬 API 서비스
  final _kakaoLocalService = KakaoLocalService();
  
  // 현재 지도 중심 좌표 (기본값: 풍무역)
  double _currentMapCenterLat = 37.6161;
  double _currentMapCenterLng = 126.7168;
  
  // 현재 지도 보이는 영역 (bounds)
  double _mapNorthLatitude = 37.6161;
  double _mapSouthLatitude = 37.6161;
  double _mapWestLongitude = 126.7168;
  double _mapEastLongitude = 126.7168;
  
  // 검색 로딩 상태
  bool _isSearching = false;

  // 슬라이딩 패널 컨트롤러
  final PanelController _panelController = PanelController();

  // 검색 관련
  final TextEditingController _searchController = TextEditingController();
  
  // 지도 이동 감지를 위한 타이머
  Timer? _mapMoveTimer;
  LatLng? _lastCameraPosition;

  // 카테고리 필터
  String? _selectedCategory;
  final List<String> _categories = [
    '전체',
    '한식',
    '중식',
    '일식',
    '양식',
    '패스트푸드',
    '카페',
    '디저트',
    '분식',
  ];

  @override
  void initState() {
    super.initState();
    print('🚀 MapPage initState 시작');
    
    // 라이프사이클 옵저버 등록
    WidgetsBinding.instance.addObserver(this);

    // 페이지 진입 시 권한 확인 및 다이얼로그 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📍 페이지 로드 완료 - 권한 확인 시작');
      _checkPermissionAndShowDialog();
    });
  }

  @override
  void dispose() {
    // 라이프사이클 옵저버 제거
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _mapMoveTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 다시 활성화되면 권한 재확인
    if (state == AppLifecycleState.resumed) {
      ref.read(locationProvider.notifier).recheckPermissionOnResume();

      // 권한이 허용되었으면 마커 표시
      final locationState = ref.read(locationProvider);
      if (locationState.isGranted && _isMapReady) {
        print('🔄 앱 재개 - 권한 있음, 마커 표시');
        _showRestaurantMarkers();
      }
    }
  }

  /// 권한 확인 및 다이얼로그 표시
  Future<void> _checkPermissionAndShowDialog() async {
    print('🔍 _checkPermissionAndShowDialog 시작');

    // Provider에서 권한 확인
    await ref.read(locationProvider.notifier).checkPermission();

    final locationState = ref.read(locationProvider);
    print('📋 권한 상태: ${locationState.permission}');
    print('   needsPermission: ${locationState.needsPermission}');
    print('   _dialogShown: $_dialogShown');
    print('   mounted: $mounted');

    // 권한이 필요하고 아직 다이얼로그를 표시하지 않았다면
    if (locationState.needsPermission && !_dialogShown && mounted) {
      print('✅ 다이얼로그 표시 조건 충족 - 표시 시작');
      _dialogShown = true;
      await _showPermissionDialog();
    } else if (locationState.isGranted) {
      print('✅ 권한 이미 허용됨 - onMapReady에서 마커 표시 예정');
      // 권한이 있으면 onMapReady에서 마커가 표시됨 (지도 준비 후)
    } else {
      print('⚠️ 다이얼로그 표시 안 됨 - 조건 미충족');
    }
  }

  /// 권한 다이얼로그 표시
  Future<void> _showPermissionDialog() async {
    print('🎯 _showPermissionDialog 호출됨');
    final locationState = ref.read(locationProvider);

    print('   isPermanentlyDenied: ${locationState.isPermanentlyDenied}');

    await LocationPermissionDialog.show(
      context,
      isPermanentlyDenied: locationState.isPermanentlyDenied,
      onDeny: () {
        print('❌ 사용자가 권한 거절');
        Navigator.of(context).pop();
        _dialogShown = false;
        // 권한 없이 지도만 표시
      },
      onAllow: () async {
        print('✅ 사용자가 권한 허용 클릭');
        Navigator.of(context).pop();
        await _handlePermissionAllow();
      },
    );
  }

  /// 허용 버튼 클릭 처리
  Future<void> _handlePermissionAllow() async {
    print('🔑 _handlePermissionAllow 시작');
    final locationNotifier = ref.read(locationProvider.notifier);
    final currentState = ref.read(locationProvider);

    print('   현재 상태: ${currentState.permission}');

    if (currentState.isPermanentlyDenied) {
      print('⚠️ 영구 거부 상태 → 설정 열기');
      // 영구 거부 상태 → 설정 열기
      await locationNotifier.openSettings();
      _dialogShown = false; // 설정에서 돌아올 때 재확인 위해 리셋
    } else {
      print('📱 권한 요청 시작...');
      // 일반 거부 상태 → 권한 요청
      final result = await locationNotifier.requestPermission();
      print('📱 권한 요청 결과: $result');

      if (result == LocationPermission.always ||
          result == LocationPermission.whileInUse) {
        print('✅ 권한 획득 성공!');
        // 권한 획득 성공 → 마커 표시 및 현재 위치로 이동
        _showRestaurantMarkers();
        await _moveToCurrentLocation();
      } else if (result == LocationPermission.deniedForever) {
        print('⚠️ 영구 거부됨 → 다이얼로그 재표시');
        // 이번에 영구 거부됨 → 설정 안내 다이얼로그 재표시
        _dialogShown = false;
        _checkPermissionAndShowDialog();
      } else {
        print('❌ 권한 거부됨: $result');
      }
      _dialogShown = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ MapPage build 호출됨');
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 상단 흰색 영역 (검색바 + 카테고리)
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // 상단 여백
                SizedBox(height: topPadding),
                
                // 검색바
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      // 뒤로가기 버튼
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      SizedBox(width: 12.w),

                      // 검색바
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: AppColors.mutedForeground, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                '맛집 검색',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 카테고리 필터
                _buildCategoryFilter(),
                SizedBox(height: 8.h),
              ],
            ),
          ),

          // 지도 영역
          Expanded(
            child: Stack(
              children: [
                // 카카오맵 (GestureDetector로 감싸서 탭 감지)
                GestureDetector(
                  onTapUp: (details) => _onMapTap(details.localPosition),
                  child: KakaoMap(
                    onMapReady: _onMapReady,
                    option: const KakaoMapOption(
                      position: LatLng(37.6161, 126.7168), // 풍무역
                    ),
                  ),
                ),

                // "이 위치에서 검색" 버튼 (지도 위에 배치)
                Positioned(
                  top: 16.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 200.w),
                      child: _buildSearchHereButton(),
                    ),
                  ),
                ),

                // 슬라이딩 패널
                SlidingUpPanel(
                  controller: _panelController,
                  minHeight: 140.h,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                  panel: _buildRestaurantList(),
                  body: const SizedBox.shrink(),
                  onPanelSlide: (position) {
                    setState(() {
                      _panelPosition = position;
                    });
                  },
                ),
                
                // 현재 위치 버튼 (슬라이딩 패널과 함께 움직임)
                Positioned(
                  bottom: _calculateButtonPosition(),
                  right: 16.w,
                  child: FloatingActionButton(
                    heroTag: 'current_location',
                    backgroundColor: Colors.white,
                    elevation: 4,
                    onPressed: _moveToCurrentLocation,
                    child: _isLoadingLocation
                        ? SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(Icons.my_location, color: AppColors.primary, size: 24.sp),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 예제 코드 구조를 따라서 onMapReady 콜백 분리
  void _onMapReady(KakaoMapController controller) {
    print('🗺️🗺️🗺️ 카카오 지도가 정상적으로 불러와졌습니다!');
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
    print('✅ 지도 컨트롤러 설정 완료');
    
    // 지도 이동 감지 타이머 시작
    _startMapMoveDetection();
    
    // 권한이 있으면 현재 위치로 이동 및 마커 표시
    _moveToCurrentLocationIfPermitted();
  }

  /// 지도 이동 감지 타이머 시작
  void _startMapMoveDetection() {
    _mapMoveTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_isMapReady || !mounted) return;
      
      try {
        final cameraPosition = await _mapController.getCameraPosition();
        final currentPos = cameraPosition.position;
        
        // 이전 위치와 현재 위치를 비교
        if (_lastCameraPosition == null ||
            (_lastCameraPosition!.latitude - currentPos.latitude).abs() > 0.0001 ||
            (_lastCameraPosition!.longitude - currentPos.longitude).abs() > 0.0001) {
          
          _lastCameraPosition = currentPos;
          
          // 지도가 이동했으면 필터링 업데이트
          if (_restaurants.isNotEmpty) {
            await _onMapMoved();
          }
        }
      } catch (e) {
        // 에러 무시 (지도가 준비되지 않았을 수 있음)
      }
    });
  }

  /// 지도 이동 후 호출 - 보이는 영역에 맞춰 필터링
  /// (카카오맵 SDK에 onCameraIdle이 없어서 수동으로 호출)
  Future<void> _onMapMoved() async {
    if (!_isMapReady) return;
    
    print('📸 지도 이동 완료 - 보이는 영역 계산');
    await _updateVisibleArea();
    _filterVisibleRestaurants();
  }

  /// 현재 지도에서 보이는 영역 계산
  Future<void> _updateVisibleArea() async {
    if (!_isMapReady) return;
    
    try {
      // 카카오맵 SDK에서 현재 카메라 위치 가져오기
      final cameraPosition = await _mapController.getCameraPosition();
      
      // 지도 중심 좌표 업데이트
      _currentMapCenterLat = cameraPosition.position.latitude;
      _currentMapCenterLng = cameraPosition.position.longitude;
      
      print('📍 현재 지도 중심: lat=$_currentMapCenterLat, lng=$_currentMapCenterLng');
      
      // 줌 레벨에 따라 보이는 영역 계산
      // 줌 레벨이 높을수록 더 좁은 영역
      final zoomLevel = cameraPosition.zoomLevel;
      
      // 줌 레벨에 따른 영역 크기 조정
      // zoomLevel 15 = 약 0.01도 (1.1km)
      // zoomLevel 13 = 약 0.02도 (2.2km)
      final delta = 0.02 / (zoomLevel / 13.0);
      
      _mapNorthLatitude = _currentMapCenterLat + delta;
      _mapSouthLatitude = _currentMapCenterLat - delta;
      _mapEastLongitude = _currentMapCenterLng + delta;
      _mapWestLongitude = _currentMapCenterLng - delta;
      
      print('🌍 보이는 영역: N=$_mapNorthLatitude, S=$_mapSouthLatitude, W=$_mapWestLongitude, E=$_mapEastLongitude (zoom=$zoomLevel)');
    } catch (e) {
      print('⚠️ 카메라 위치 가져오기 실패: $e');
      // 폴백: 기존 값 사용
      final double latitudeDelta = 0.015;
      final double longitudeDelta = 0.015;
      
      _mapNorthLatitude = _currentMapCenterLat + latitudeDelta;
      _mapSouthLatitude = _currentMapCenterLat - latitudeDelta;
      _mapEastLongitude = _currentMapCenterLng + longitudeDelta;
      _mapWestLongitude = _currentMapCenterLng - longitudeDelta;
    }
  }

  /// 보이는 영역 내의 식당만 필터링
  void _filterVisibleRestaurants() {
    // 선택된 식당이 있으면 그것만 표시
    if (_selectedRestaurant != null) {
      setState(() {
        _visibleRestaurants = [_selectedRestaurant!];
      });
      print('🎯 선택된 식당만 표시: ${_selectedRestaurant!.name}');
      return;
    }

    // 보이는 영역 내의 식당만 필터링
    final visible = _restaurants.where((restaurant) {
      final lat = restaurant.latitude;
      final lng = restaurant.longitude;
      
      final isVisible = lat >= _mapSouthLatitude &&
          lat <= _mapNorthLatitude &&
          lng >= _mapWestLongitude &&
          lng <= _mapEastLongitude;
      
      return isVisible;
    }).toList();

    setState(() {
      _visibleRestaurants = visible;
    });
    
    print('👀 화면에 보이는 식당: ${visible.length}개 / 전체: ${_restaurants.length}개');
  }

  /// 플로팅 버튼 위치 계산 (패널과 함께 움직임)
  double _calculateButtonPosition() {
    final minHeight = 140.h;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final buttonOffset = 10.h; // 패널 위로 약간 올림
    
    // 패널 높이에 따라 버튼 위치 계산
    // position: 0.0 (닫힘) ~ 1.0 (열림)
    final currentPanelHeight = minHeight + (maxHeight - minHeight) * _panelPosition;
    return currentPanelHeight + buttonOffset;
  }

  /// 권한이 있으면 자동으로 마커 표시 및 현재 위치로 이동
  Future<void> _moveToCurrentLocationIfPermitted() async {
    await ref.read(locationProvider.notifier).checkPermission();
    final locationState = ref.read(locationProvider);

    print('🔍 onMapReady 권한 확인: ${locationState.permission}');

    if (locationState.isGranted) {
      print('✅ 권한 있음 - 마커 표시 및 위치 이동');
      // 마커 표시
      await _showRestaurantMarkers();
      // 현재 위치로 이동
      await _moveToCurrentLocation();
    } else {
      print('❌ 권한 없음 - 대기');
    }
  }

  /// 현재 위치로 이동
  Future<void> _moveToCurrentLocation() async {
    if (!_isMapReady) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationNotifier = ref.read(locationProvider.notifier);
      final locationState = ref.read(locationProvider);

      // 권한이 없으면 종료
      if (!locationState.isGranted) {
        print('❌ 권한 없음 - 위치 이동 불가');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('위치 권한이 필요합니다', style: TextStyle(fontSize: 14.sp)),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // Provider에서 현재 위치 가져오기
      if (locationState.position == null) {
        await locationNotifier.getCurrentPosition();
      }

      final position = ref.read(locationProvider).position;
      if (position != null) {
        print('✅ 현재 위치: ${position.latitude}, ${position.longitude}');
        
        // 지도 중심 좌표 업데이트
        _currentMapCenterLat = position.latitude;
        _currentMapCenterLng = position.longitude;
        
        // 카카오맵 SDK 카메라 이동
        await _mapController.moveCamera(
          CameraUpdate.newCenterPosition(
            LatLng(position.latitude, position.longitude),
          ),
          animation: const CameraAnimation(500), // 0.5초 애니메이션
        );
        
        // 지도 이동 후 보이는 영역 업데이트 및 필터링
        _onMapMoved();
        
        print('🗺️ 지도 이동 완료');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('현재 위치로 이동했습니다', style: TextStyle(fontSize: 14.sp)),
            duration: const Duration(seconds: 1),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        print('❌ 위치 정보 없음');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('위치를 가져올 수 없습니다', style: TextStyle(fontSize: 14.sp)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 위치 가져오기 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('위치 이동 중 오류가 발생했습니다', style: TextStyle(fontSize: 14.sp)),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // 주변 식당 마커 표시 (사용 안함 - 대신 _searchRestaurantsAtCurrentLocation 사용)
  Future<void> _showRestaurantMarkers() async {
    print('📍 _showRestaurantMarkers 호출됨 (deprecated)');
    // 이 함수는 더 이상 사용하지 않음
    // 대신 "이 위치에서 검색" 버튼을 통해 _searchRestaurantsAtCurrentLocation 호출
  }

  /// 검색 결과를 지도에 마커로 표시 (카카오맵 베스트 프랙티스)
  Future<void> _showRestaurantMarkersOnMap(List<RestaurantModel> restaurants) async {
    if (!_isMapReady) {
      print('❌ 지도가 준비되지 않음');
      return;
    }

    try {
      // 1. 기존 마커 모두 제거
      print('🗑️ 기존 마커 ${_markers.length}개 제거 시작');
      for (var marker in _markers.values) {
        try {
          await _mapController.labelLayer.removePoi(marker);
        } catch (e) {
          print('⚠️ 마커 제거 실패: $e');
        }
      }
      _markers.clear();
      print('✅ 기존 마커 제거 완료');

      // 2. 마커 스타일 정의 (카카오맵 베스트 프랙티스)
      // assets/icons/marker.png 파일 사용
      // 20x30px 파란색 위치 마커 PNG
      final poiStyle = PoiStyle(
        icon: KImage.fromAsset('assets/icons/marker.png', 20, 30),
      );

      // 3. 새 마커 추가
      print('📍 ${restaurants.length}개 마커 추가 시작');
      
      for (final restaurant in restaurants) {
        try {
          // 마커 추가 (카카오맵 공식 방법)
          // 참고: 카카오맵 SDK는 마커 클릭 이벤트를 직접 지원하지 않음
          // 대신 리스트에서 식당을 선택하면 지도에 표시됩니다
          final poi = await _mapController.labelLayer.addPoi(
            LatLng(restaurant.latitude, restaurant.longitude),
            style: poiStyle,
          );
          
          _markers[restaurant.id] = poi; // ID를 key로 사용
          print('  ✅ 마커 추가 성공: ${restaurant.name}');
        } catch (e) {
          print('  ❌ 마커 추가 실패 (${restaurant.name}): $e');
        }
      }

      print('🎯 마커 추가 완료: ${_markers.length}개');
      
    } catch (e) {
      print('❌❌❌ 마커 표시 중 오류: $e');
      print('   💡 assets/icons/marker.png 파일이 있는지 확인하세요');
      print('   💡 pubspec.yaml에 assets 경로가 등록되었는지 확인하세요');
    }
  }

  /// 지도 탭 시 가장 가까운 식당 찾기
  Future<void> _onMapTap(Offset tapPosition) async {
    if (_visibleRestaurants.isEmpty || !_isMapReady) return;
    
    try {
      // 탭 위치를 지도 좌표로 변환
      final screenSize = MediaQuery.of(context).size;
      final cameraPosition = await _mapController.getCameraPosition();
      
      // 화면 크기와 줌 레벨을 기반으로 탭 위치의 대략적인 위도/경도 계산
      final delta = 0.02 / (cameraPosition.zoomLevel / 13.0);
      final latPerPixel = (delta * 2) / screenSize.height;
      final lngPerPixel = (delta * 2) / screenSize.width;
      
      // 지도 상단부터의 오프셋 계산 (상단 UI 제외)
      final topPadding = MediaQuery.of(context).padding.top + 170.h; // 상단 UI 높이
      final adjustedY = tapPosition.dy - topPadding;
      
      // 탭 위치의 위도/경도 계산
      final centerLat = cameraPosition.position.latitude;
      final centerLng = cameraPosition.position.longitude;
      
      final tapLat = centerLat + (screenSize.height / 2 - adjustedY) * latPerPixel;
      final tapLng = centerLng + (tapPosition.dx - screenSize.width / 2) * lngPerPixel;
      
      print('🖱️ 지도 탭: lat=$tapLat, lng=$tapLng');
      
      // 탭 위치에서 가장 가까운 식당 찾기 (50m 이내)
      RestaurantModel? nearestRestaurant;
      double minDistance = 0.0005; // 약 50m (위도/경도 차이)
      
      for (final restaurant in _visibleRestaurants) {
        final distance = ((restaurant.latitude - tapLat).abs() + 
                         (restaurant.longitude - tapLng).abs());
        
        if (distance < minDistance) {
          minDistance = distance;
          nearestRestaurant = restaurant;
        }
      }
      
      // 가까운 식당을 찾았으면 선택
      if (nearestRestaurant != null) {
        print('🎯 가장 가까운 식당 발견: ${nearestRestaurant.name}');
        _onRestaurantSelected(nearestRestaurant);
      } else {
        print('❌ 근처에 식당 없음');
      }
    } catch (e) {
      print('⚠️ 지도 탭 처리 실패: $e');
    }
  }

  /// 식당 리스트에서 선택 시 호출
  void _onRestaurantSelected(RestaurantModel restaurant) {
    print('🎯 식당 선택: ${restaurant.name}');
    
    setState(() {
      _selectedRestaurant = restaurant;
    });
    
    // 지도를 해당 위치로 이동
    _mapController.moveCamera(
      CameraUpdate.newCenterPosition(
        LatLng(restaurant.latitude, restaurant.longitude),
      ),
      animation: const CameraAnimation(300),
    );
    
    // 슬라이드 패널 열기
    if (!_panelController.isPanelOpen) {
      _panelController.open();
    }
    
    // 필터링 업데이트
    _filterVisibleRestaurants();
    
    // 스낵바 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${restaurant.name} 선택됨', style: TextStyle(fontSize: 14.sp)),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  /// 카테고리 필터 빌드
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 42.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category ||
              (_selectedCategory == null && category == '전체');

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (category == '전체') {
                    _selectedCategory = null;
                  } else {
                    _selectedCategory = category;
                  }
                  // 마커 갱신 (나중에 활성화)
                  // _showRestaurantMarkers();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isSelected ? Colors.white : AppColors.foreground,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// "이 화면에서 검색" 버튼 빌드
  Widget _buildSearchHereButton() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24.r),
      child: InkWell(
        onTap: _isSearching ? null : _searchRestaurantsAtCurrentLocation,
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: _isSearching ? AppColors.muted : AppColors.primary,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSearching)
                SizedBox(
                  width: 18.w,
                  height: 18.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(Icons.refresh, color: Colors.white, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                _isSearching ? '검색 중...' : '이 화면에서 검색',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 현재 화면에서 음식점 검색 (화면 중심 기반)
  Future<void> _searchRestaurantsAtCurrentLocation() async {
    setState(() {
      _isSearching = true;
      _selectedRestaurant = null; // 선택 초기화
    });

    try {
      // 1. 먼저 현재 화면 중심 좌표를 가져옴
      await _updateVisibleArea();
      
      print('🔍 화면 중심에서 검색 시작: lat=$_currentMapCenterLat, lng=$_currentMapCenterLng');
      
      // 2. 보이는 영역의 대략적인 반경 계산 (위도 차이를 km로 변환)
      final latDiff = _mapNorthLatitude - _mapSouthLatitude;
      final radiusInKm = (latDiff * 111.0) / 2; // 위도 1도 ≈ 111km
      final radiusInMeters = (radiusInKm * 1000).toInt().clamp(500, 20000); // 최소 500m, 최대 20km

      print('📐 검색 반경: ${radiusInMeters}m (화면 기반)');

      // 3. 카카오 로컬 API로 음식점 검색
      final allRestaurants = <RestaurantModel>[];
      int pageCount = 0;
      
      // 모든 페이지 가져오기 (API가 끝날 때까지)
      for (int page = 1; page <= 3; page++) {
        try {
          final response = await _kakaoLocalService.searchByCategory(
            categoryGroupCode: 'FD6',
            x: _currentMapCenterLng,
            y: _currentMapCenterLat,
            radius: radiusInMeters,
            size: 15,
            page: page,
          );
          
          final documents = response['documents'] as List<dynamic>? ?? [];
          print('📄 페이지 $page: ${documents.length}개 발견');
          
          if (documents.isEmpty) {
            print('📄 페이지 $page: 결과 없음 - 검색 중단');
            break;
          }
          
          final restaurants = documents
              .map((doc) => RestaurantModel.fromKakaoApi(doc as Map<String, dynamic>))
              .toList();
          
          allRestaurants.addAll(restaurants);
          pageCount++;
          
          final meta = response['meta'] as Map<String, dynamic>?;
          final isEnd = meta?['is_end'] as bool? ?? true;
          print('📄 페이지 $page: is_end=$isEnd');
          
          if (isEnd) {
            print('📄 마지막 페이지 도달 - 검색 완료');
            break;
          }
        } catch (e) {
          print('⚠️ 페이지 $page 요청 실패: $e');
          break;
        }
      }

      print('✅ 검색 완료: 총 ${allRestaurants.length}개 음식점 발견 ($pageCount 페이지)');

      // 4. 전체 식당 목록 저장
      setState(() {
        _restaurants = allRestaurants;
      });

      // 5. 지도에 마커 표시
      await _showRestaurantMarkersOnMap(allRestaurants);

      // 6. 화면에 보이는 영역만 필터링
      await _onMapMoved();

      // 7. 결과 안내
      if (allRestaurants.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('주변에 음식점이 없습니다', style: TextStyle(fontSize: 14.sp)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '화면에 ${_visibleRestaurants.length}곳 표시 중 (전체 ${allRestaurants.length}곳)', 
                style: TextStyle(fontSize: 14.sp)
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ 음식점 검색 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('검색 중 오류가 발생했습니다', style: TextStyle(fontSize: 14.sp)),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  /// 하단 식당 리스트 빌드
  Widget _buildRestaurantList() {
    // 선택된 식당이 있으면 그것만, 없으면 보이는 영역의 식당들 표시
    final displayRestaurants = _selectedRestaurant != null
        ? [_selectedRestaurant!]
        : _visibleRestaurants;
    
    // 카테고리 필터링
    final filteredRestaurants = _selectedCategory == null
        ? displayRestaurants
        : displayRestaurants.where((r) => r.category == _selectedCategory).toList();

    return Column(
      children: [
        // 드래그 핸들
        Container(
          margin: EdgeInsets.only(top: 12.h),
          width: 40.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),

        // 헤더
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _selectedRestaurant != null
                        ? '선택된 맛집'
                        : '화면에 보이는 맛집 ${filteredRestaurants.length}곳',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                  if (_selectedRestaurant != null) ...[
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRestaurant = null;
                        });
                        _filterVisibleRestaurants();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '전체보기',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(Icons.close, size: 14.sp, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              IconButton(
                icon: Icon(Icons.list, size: 24.sp),
                onPressed: () {
                  // 패널 열기/닫기
                  if (_panelController.isPanelOpen) {
                    _panelController.close();
                  } else {
                    _panelController.open();
                  }
                },
              ),
            ],
          ),
        ),

        // 식당 리스트
        Expanded(
          child: filteredRestaurants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _restaurants.isEmpty
                            ? '"이 화면에서 검색" 버튼을 눌러주세요'
                            : '화면에 보이는 맛집이 없습니다\n지도를 이동해보세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: filteredRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = filteredRestaurants[index];
                    return _buildRestaurantCard(restaurant);
                  },
                ),
        ),
      ],
    );
  }

  /// 식당 카드 빌드
  Widget _buildRestaurantCard(RestaurantModel restaurant) {
    final isSelected = _selectedRestaurant?.id == restaurant.id;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppColors.primaryLight : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: isSelected 
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          // 선택되지 않았으면 선택, 선택되었으면 상세 정보 표시
          if (!isSelected) {
            _onRestaurantSelected(restaurant);
          } else {
            _showRestaurantInfo(restaurant);
          }
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // 식당 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름
                    Text(
                      restaurant.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // 카테고리 및 거리
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            restaurant.category,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.location_on,
                          size: 12.sp,
                          color: AppColors.mutedForeground,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          restaurant.distanceText,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),

                    // 평점
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14.sp, color: Colors.amber),
                        SizedBox(width: 2.w),
                        Text(
                          restaurant.rating.toString(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 화살표 아이콘
              Icon(
                Icons.chevron_right,
                color: AppColors.mutedForeground,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 식당 정보 표시
  void _showRestaurantInfo(RestaurantModel restaurant) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 식당 이름
            Text(
              restaurant.name,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            SizedBox(height: 8.h),

            // 카테고리 및 거리
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    restaurant.category,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.location_on, size: 16.sp, color: AppColors.mutedForeground),
                SizedBox(width: 4.w),
                Text(
                  restaurant.distanceText,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),

            // 평점
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.star, size: 16.sp, color: Colors.amber),
                SizedBox(width: 4.w),
                Text(
                  restaurant.rating.toString(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),

            // 설명
            if (restaurant.description != null) ...[
              SizedBox(height: 12.h),
              Text(
                restaurant.description!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],

            SizedBox(height: 16.h),

            // 길찾기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // 길찾기 기능은 추후 구현 예정
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('길찾기 기능은 준비 중입니다', style: TextStyle(fontSize: 14.sp)),
                    ),
                  );
                },
                icon: Icon(Icons.directions, size: 20.sp),
                label: Text('길찾기', style: TextStyle(fontSize: 16.sp)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
