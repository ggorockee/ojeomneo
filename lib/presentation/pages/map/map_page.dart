import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/google_places_service.dart';
import '../../mock/restaurant_model.dart';
import '../../providers/location_provider.dart';
import '../../widgets/location_permission_dialog.dart';
import '../../widgets/place_bottom_card.dart';

class MapPage extends ConsumerStatefulWidget {
  final String? category;

  const MapPage({super.key, this.category});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  List<RestaurantModel> _restaurants = [];
  List<RestaurantModel> _visibleRestaurants = [];
  RestaurantModel? _selectedRestaurant;
  bool _isLoadingLocation = false;
  bool _dialogShown = false;
  bool _isMapReady = false;
  Set<Marker> _markers = {};
  double _panelPosition = 0.0;
  bool _showLocationButton = true;

  final _googlePlacesService = GooglePlacesService();

  double _currentMapCenterLat = 37.6161;
  double _currentMapCenterLng = 126.7168;

  double _mapNorthLatitude = 37.6161;
  double _mapSouthLatitude = 37.6161;
  double _mapWestLongitude = 126.7168;
  double _mapEastLongitude = 126.7168;

  bool _isSearching = false;
  bool _showCategoryMenu = false; // 카테고리 메뉴 표시 여부

  final TextEditingController _searchController = TextEditingController();

  Timer? _mapMoveTimer;
  LatLng? _lastCameraPosition;

  String? _selectedCategory;
  final List<Map<String, String>> _categories = [
    {'name': '전체', 'type': 'restaurant'},
    {'name': '음식점', 'type': 'restaurant'},
    {'name': '카페', 'type': 'cafe'},
    {'name': '베이커리', 'type': 'bakery'},
    {'name': '술집', 'type': 'bar'},
  ];

  @override
  void initState() {
    super.initState();
    print('🚀 MapPage initState 시작');

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📍 페이지 로드 완료 - 권한 확인 시작');
      _checkPermissionAndShowDialog();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _mapMoveTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      ref.read(locationProvider.notifier).recheckPermissionOnResume();

      final locationState = ref.read(locationProvider);
      if (locationState.isGranted && _isMapReady) {
        print('🔄 앱 재개 - 권한 있음, 마커 표시');
        _showRestaurantMarkers();
        // Show location button when returning to app
        setState(() {
          _showLocationButton = true;
        });
      }
    }
  }

  Future<void> _checkPermissionAndShowDialog() async {
    print('🔍 _checkPermissionAndShowDialog 시작');

    await ref.read(locationProvider.notifier).checkPermission();

    final locationState = ref.read(locationProvider);
    print('📋 권한 상태: ${locationState.permission}');
    print('   needsPermission: ${locationState.needsPermission}');
    print('   _dialogShown: $_dialogShown');
    print('   mounted: $mounted');

    if (locationState.needsPermission && !_dialogShown && mounted) {
      print('✅ 다이얼로그 표시 조건 충족 - 표시 시작');
      _dialogShown = true;
      await _showPermissionDialog();
    } else if (locationState.isGranted) {
      print('✅ 권한 이미 허용됨 - onMapReady에서 마커 표시 예정');
    } else {
      print('⚠️ 다이얼로그 표시 안 됨 - 조건 미충족');
    }
  }

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
      },
      onAllow: () async {
        print('✅ 사용자가 권한 허용 클릭');
        Navigator.of(context).pop();
        await _handlePermissionAllow();
      },
    );
  }

  Future<void> _handlePermissionAllow() async {
    print('🔑 _handlePermissionAllow 시작');
    final locationNotifier = ref.read(locationProvider.notifier);
    final currentState = ref.read(locationProvider);

    print('   현재 상태: ${currentState.permission}');

    if (currentState.isPermanentlyDenied) {
      print('⚠️ 영구 거부 상태 → 설정 열기');
      await locationNotifier.openSettings();
      _dialogShown = false;
    } else {
      print('📱 권한 요청 시작...');
      final result = await locationNotifier.requestPermission();
      print('📱 권한 요청 결과: $result');

      if (result == LocationPermission.always ||
          result == LocationPermission.whileInUse) {
        print('✅ 권한 획득 성공!');
        _showRestaurantMarkers();
        await _moveToCurrentLocation();
      } else if (result == LocationPermission.deniedForever) {
        print('⚠️ 영구 거부됨 → 다이얼로그 재표시');
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // 전체 화면 지도
          GoogleMap(
            onMapCreated: _onMapReady,
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentMapCenterLat, _currentMapCenterLng),
              zoom: 15.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onCameraMove: (CameraPosition position) {
              _currentMapCenterLat = position.target.latitude;
              _currentMapCenterLng = position.target.longitude;
            },
            onCameraIdle: _onMapMoved,
          ),

          // 상단 검색바 (Floating)
          Positioned(
            top: topPadding + 12.h,
            left: 16.w,
            right: 16.w,
            child: _buildFloatingSearchBar(),
          ),

          // 우측 하단 버튼들
          Positioned(
            bottom: bottomPadding + 16.h,
            right: 16.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 카테고리 버튼
                FloatingActionButton(
                  heroTag: 'category',
                  backgroundColor: Colors.white,
                  elevation: 4,
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _showCategoryMenu = !_showCategoryMenu;
                    });
                  },
                  child: Icon(
                    Icons.filter_list,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(height: 12.h),

                // 검색 버튼
                if (!_isSearching)
                  FloatingActionButton(
                    heroTag: 'search',
                    backgroundColor: AppColors.primary,
                    elevation: 4,
                    onPressed: _searchRestaurantsAtCurrentLocation,
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  )
                else
                  FloatingActionButton(
                    heroTag: 'searching',
                    backgroundColor: Colors.grey[600],
                    elevation: 4,
                    onPressed: null,
                    child: SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                SizedBox(height: 12.h),

                // 내 위치 버튼
                if (_showLocationButton)
                  FloatingActionButton(
                    heroTag: 'current_location',
                    backgroundColor: Colors.white,
                    elevation: 4,
                    mini: true,
                    onPressed: _moveToCurrentLocation,
                    child: _isLoadingLocation
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue[600],
                            ),
                          )
                        : Icon(
                            Icons.my_location,
                            color: Colors.blue[600],
                            size: 20.sp,
                          ),
                  ),
              ],
            ),
          ),

          // 카테고리 메뉴 (Floating)
          if (_showCategoryMenu)
            Positioned(
              bottom: bottomPadding + 150.h,
              right: 16.w,
              child: _buildCategoryMenu(),
            ),

          // 하단 장소 카드
          if (_selectedRestaurant != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPadding,
              child: PlaceBottomCard(
                restaurant: _selectedRestaurant!,
                onTap: () => _showPlaceDetails(_selectedRestaurant!),
                onClose: () {
                  setState(() {
                    _selectedRestaurant = null;
                    _showLocationButton = true;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  void _onMapReady(GoogleMapController controller) {
    print('🗺️🗺️🗺️ 구글 지도가 정상적으로 불러와졌습니다!');
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
    print('✅ 지도 컨트롤러 설정 완료');

    _moveToCurrentLocationIfPermitted();
  }

  Future<void> _onMapMoved() async {
    if (!_isMapReady) return;

    print('📸 지도 이동 완료 - 보이는 영역 계산');
    await _updateVisibleArea();
    _filterVisibleRestaurants();
  }

  Future<void> _updateVisibleArea() async {
    if (!_isMapReady || _mapController == null) return;

    try {
      final bounds = await _mapController!.getVisibleRegion();

      _mapNorthLatitude = bounds.northeast.latitude;
      _mapSouthLatitude = bounds.southwest.latitude;
      _mapEastLongitude = bounds.northeast.longitude;
      _mapWestLongitude = bounds.southwest.longitude;

      print('🌍 보이는 영역: N=$_mapNorthLatitude, S=$_mapSouthLatitude, W=$_mapWestLongitude, E=$_mapEastLongitude');
    } catch (e) {
      print('⚠️ 보이는 영역 가져오기 실패: $e');
    }
  }

  void _filterVisibleRestaurants() {
    if (_selectedRestaurant != null) {
      setState(() {
        _visibleRestaurants = [_selectedRestaurant!];
      });
      print('🎯 선택된 식당만 표시: ${_selectedRestaurant!.name}');
      return;
    }

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

  Future<void> _moveToCurrentLocationIfPermitted() async {
    await ref.read(locationProvider.notifier).checkPermission();
    final locationState = ref.read(locationProvider);

    print('🔍 onMapReady 권한 확인: ${locationState.permission}');

    if (locationState.isGranted) {
      print('✅ 권한 있음 - 마커 표시 및 위치 이동');
      await _showRestaurantMarkers();
      await _moveToCurrentLocation();
    } else {
      print('❌ 권한 없음 - 대기');
    }
  }

  Future<void> _moveToCurrentLocation() async {
    if (!_isMapReady || _mapController == null) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationNotifier = ref.read(locationProvider.notifier);
      final locationState = ref.read(locationProvider);

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

      if (locationState.position == null) {
        await locationNotifier.getCurrentPosition();
      }

      final position = ref.read(locationProvider).position;
      if (position != null) {
        print('✅ 현재 위치: ${position.latitude}, ${position.longitude}');

        _currentMapCenterLat = position.latitude;
        _currentMapCenterLng = position.longitude;

        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0,
            ),
          ),
        );

        await _onMapMoved();

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

  Future<void> _showRestaurantMarkers() async {
    print('📍 _showRestaurantMarkers 호출됨 (deprecated)');
  }

  Future<void> _showRestaurantMarkersOnMap(List<RestaurantModel> restaurants) async {
    if (!_isMapReady) {
      print('❌ 지도가 준비되지 않음');
      return;
    }

    try {
      print('🗑️ 기존 마커 ${_markers.length}개 제거 시작');

      final newMarkers = <Marker>{};

      print('📍 ${restaurants.length}개 마커 추가 시작');

      for (final restaurant in restaurants) {
        try {
          final marker = Marker(
            markerId: MarkerId(restaurant.id),
            position: LatLng(restaurant.latitude, restaurant.longitude),
            infoWindow: InfoWindow(
              title: restaurant.name,
              snippet: restaurant.category,
            ),
            onTap: () => _onRestaurantSelected(restaurant),
          );

          newMarkers.add(marker);
          print('  ✅ 마커 추가 성공: ${restaurant.name}');
        } catch (e) {
          print('  ❌ 마커 추가 실패 (${restaurant.name}): $e');
        }
      }

      setState(() {
        _markers = newMarkers;
      });

      print('🎯 마커 추가 완료: ${_markers.length}개');

    } catch (e) {
      print('❌❌❌ 마커 표시 중 오류: $e');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  void _onRestaurantSelected(RestaurantModel restaurant) {
    print('🎯 장소 선택: ${restaurant.name}');

    setState(() {
      _selectedRestaurant = restaurant;
      _showLocationButton = false;
    });

    // 구글맵 스타일: 마커 위치로 카메라 이동
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(restaurant.latitude, restaurant.longitude),
      ),
    );
  }

  /// 구글맵 스타일 장소 상세 정보 (전체 화면 Bottom Sheet)
  void _showPlaceDetails(RestaurantModel restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Container(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 드래그 핸들
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 장소명
                  Text(
                    restaurant.name,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // 카테고리 & 거리
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

                  SizedBox(height: 12.h),

                  // 평점
                  if (restaurant.rating > 0)
                    Row(
                      children: [
                        Icon(Icons.star, size: 20.sp, color: Colors.amber),
                        SizedBox(width: 4.w),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '(Google 평점)',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '평점 정보 없음',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.mutedForeground,
                      ),
                    ),

                  if (restaurant.address != null) ...[
                    SizedBox(height: 16.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.place, size: 20.sp, color: AppColors.mutedForeground),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            restaurant.address!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (restaurant.phone != null) ...[
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 20.sp, color: AppColors.mutedForeground),
                        SizedBox(width: 8.w),
                        Text(
                          restaurant.phone!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 24.h),

                  // 액션 버튼
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('길찾기 기능은 준비 중입니다',
                                    style: TextStyle(fontSize: 14.sp)),
                              ),
                            );
                          },
                          icon: Icon(Icons.directions, size: 20.sp),
                          label: Text('길찾기', style: TextStyle(fontSize: 16.sp)),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            side: BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('전화 기능은 준비 중입니다',
                                    style: TextStyle(fontSize: 14.sp)),
                              ),
                            );
                          },
                          icon: Icon(Icons.call, size: 20.sp),
                          label: Text('전화', style: TextStyle(fontSize: 16.sp)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // TODO: Google Places Details API 연동 필요
                  Text(
                    '리뷰, 사진, 영업시간 등 상세 정보는 Google Places Details API 연동 후 표시됩니다.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.mutedForeground,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 구글맵 스타일 Floating 검색바
  Widget _buildFloatingSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '장소 검색',
          hintStyle: TextStyle(
            fontSize: 16.sp,
            color: AppColors.mutedForeground,
          ),
          prefixIcon: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.foreground, size: 24.sp),
            onPressed: () => Navigator.pop(context),
          ),
          suffixIcon: Icon(Icons.mic, color: AppColors.mutedForeground, size: 24.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
        onSubmitted: (value) {
          // TODO: Google Places Autocomplete 구현
        },
      ),
    );
  }

  /// 구글맵 스타일 카테고리 메뉴 (Popup)
  Widget _buildCategoryMenu() {
    return Container(
      width: 180.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _categories.map((category) {
          final categoryName = category['name']!;
          final isSelected = _selectedCategory == categoryName ||
              (_selectedCategory == null && categoryName == '전체');

          return InkWell(
            onTap: () {
              setState(() {
                if (categoryName == '전체') {
                  _selectedCategory = null;
                } else {
                  _selectedCategory = categoryName;
                }
                _showCategoryMenu = false;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  if (isSelected)
                    Icon(Icons.check, color: AppColors.primary, size: 20.sp),
                  if (isSelected) SizedBox(width: 8.w),
                  Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isSelected ? AppColors.primary : AppColors.foreground,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchHereButton() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: _isSearching ? null : _searchRestaurantsAtCurrentLocation,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: _isSearching ? Colors.grey[600] : AppColors.primary,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSearching)
                SizedBox(
                  width: 18.w,
                  height: 18.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(Icons.refresh, color: Colors.white, size: 20.sp),
              SizedBox(width: 6.w),
              Text(
                _isSearching ? '검색 중...' : '이 위치로 검색',
                style: TextStyle(
                  fontSize: 14.sp,
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

  Future<void> _searchRestaurantsAtCurrentLocation() async {
    setState(() {
      _isSearching = true;
      _selectedRestaurant = null;
      _showLocationButton = true; // Show button when searching
    });

    try {
      await _updateVisibleArea();

      print('🔍 Google Places API 검색 시작: lat=$_currentMapCenterLat, lng=$_currentMapCenterLng');

      final latDiff = _mapNorthLatitude - _mapSouthLatitude;
      final radiusInKm = (latDiff * 111.0) / 2;
      final radiusInMeters = (radiusInKm * 1000).toInt().clamp(500, 50000);

      print('📐 검색 반경: ${radiusInMeters}m (화면 기반)');

      // 현재 선택된 카테고리의 type 가져오기
      final selectedType = _selectedCategory != null
          ? _categories.firstWhere(
              (cat) => cat['name'] == _selectedCategory,
              orElse: () => _categories[0],
            )['type']!
          : 'restaurant';

      print('📂 카테고리: $_selectedCategory (type: $selectedType)');

      final allRestaurants = <RestaurantModel>[];
      String? nextPageToken;

      // Google Places API는 최대 3페이지까지 지원
      for (int page = 0; page < 3; page++) {
        try {
          final response = await _googlePlacesService.searchNearby(
            latitude: _currentMapCenterLat,
            longitude: _currentMapCenterLng,
            radius: radiusInMeters,
            type: selectedType,
            pageToken: nextPageToken,
          );

          final results = response['results'] as List<dynamic>? ?? [];
          print('📄 페이지 ${page + 1}: ${results.length}개 발견');

          if (results.isEmpty) {
            print('📄 페이지 ${page + 1}: 결과 없음 - 검색 중단');
            break;
          }

          final restaurants = results
              .map((place) => RestaurantModel.fromGooglePlaces(
                    place as Map<String, dynamic>,
                    _currentMapCenterLat,
                    _currentMapCenterLng,
                  ))
              .toList();

          allRestaurants.addAll(restaurants);

          nextPageToken = response['next_page_token'] as String?;
          print('📄 페이지 ${page + 1}: next_page_token=${nextPageToken != null ? "있음" : "없음"}');

          if (nextPageToken == null) {
            print('📄 마지막 페이지 도달 - 검색 완료');
            break;
          }

          // Google Places API는 next_page_token 사용 전 약간의 대기가 필요
          if (page < 2) {
            await Future.delayed(const Duration(milliseconds: 1500));
          }
        } catch (e) {
          print('⚠️ 페이지 ${page + 1} 요청 실패: $e');
          break;
        }
      }

      print('✅ 검색 완료: 총 ${allRestaurants.length}개 장소 발견');

      setState(() {
        _restaurants = allRestaurants;
      });

      await _showRestaurantMarkersOnMap(allRestaurants);

      await _onMapMoved();

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

  Widget _buildRestaurantList() {
    final displayRestaurants = _selectedRestaurant != null
        ? [_selectedRestaurant!]
        : _visibleRestaurants;

    final filteredRestaurants = _selectedCategory == null
        ? displayRestaurants
        : displayRestaurants.where((r) => r.category == _selectedCategory).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                _buildFilterButton('최신등록순', Icons.new_releases_outlined),
                SizedBox(width: 8.w),
                _buildFilterButton('거리순', Icons.navigation_outlined),
                SizedBox(width: 8.w),
                _buildFilterButton('마감임박순', Icons.access_time_outlined),
              ],
            ),
          ),

          Expanded(
            child: filteredRestaurants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _restaurants.isEmpty
                              ? '"이 위치로 검색" 버튼을 눌러주세요'
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
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    itemCount: filteredRestaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = filteredRestaurants[index];
                      return _buildRestaurantCard(restaurant);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, IconData icon) {
    final isSelected = label == '최신등록순';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    SizedBox(height: 4.h),

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

                    SizedBox(height: 4.h),
                    if (restaurant.rating > 0)
                      Row(
                        children: [
                          Icon(Icons.star, size: 14.sp, color: Colors.amber),
                          SizedBox(width: 2.w),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '평점 없음',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),

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

  void _showRestaurantInfo(RestaurantModel restaurant) {
    // Hide location button when modal appears
    setState(() {
      _showLocationButton = false;
    });

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
            Text(
              restaurant.name,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            SizedBox(height: 8.h),

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

            SizedBox(height: 8.h),
            if (restaurant.rating > 0)
              Row(
                children: [
                  Icon(Icons.star, size: 16.sp, color: Colors.amber),
                  SizedBox(width: 4.w),
                  Text(
                    restaurant.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              )
            else
              Text(
                '평점 정보 없음',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.mutedForeground,
                ),
              ),

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

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
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
    ).then((_) {
      // Show location button when modal is dismissed
      if (mounted) {
        setState(() {
          _showLocationButton = true;
        });
      }
    });
  }
}
