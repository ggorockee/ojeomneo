import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/kakao_local_service.dart';
import '../../mock/restaurant_model.dart';
import '../../providers/location_provider.dart';
import '../../widgets/location_permission_dialog.dart';

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

  final _kakaoLocalService = KakaoLocalService();

  double _currentMapCenterLat = 37.6161;
  double _currentMapCenterLng = 126.7168;

  double _mapNorthLatitude = 37.6161;
  double _mapSouthLatitude = 37.6161;
  double _mapWestLongitude = 126.7168;
  double _mapEastLongitude = 126.7168;

  bool _isSearching = false;

  final PanelController _panelController = PanelController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _mapMoveTimer;
  LatLng? _lastCameraPosition;

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SlidingUpPanel(
              controller: _panelController,
              minHeight: 180.h,
              maxHeight: MediaQuery.of(context).size.height * 0.75,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              panel: _buildRestaurantList(),
              backdropEnabled: false,
              color: Colors.transparent,
              onPanelSlide: (position) {
                setState(() {
                  _panelPosition = position;
                });
              },
              body: GoogleMap(
                onMapCreated: _onMapReady,
                initialCameraPosition: CameraPosition(
                  target: LatLng(_currentMapCenterLat, _currentMapCenterLng),
                  zoom: 15.0,
                ),
                markers: _markers,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                onCameraMove: (CameraPosition position) {
                  _currentMapCenterLat = position.target.latitude;
                  _currentMapCenterLng = position.target.longitude;
                },
                onCameraIdle: _onMapMoved,
              ),
            ),
          ),

          Positioned(
            top: topPadding + 8.h,
            left: 16.w,
            right: 16.w,
            child: _buildTopSearchBar(),
          ),

          Positioned(
            top: topPadding + 68.h,
            left: 0,
            right: 0,
            child: _buildCategoryFilter(),
          ),

          Positioned(
            top: topPadding + 130.h,
            left: 0,
            right: 0,
            child: Center(
              child: _buildSearchHereButton(),
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
    print('🎯 식당 선택: ${restaurant.name}');

    setState(() {
      _selectedRestaurant = restaurant;
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(restaurant.latitude, restaurant.longitude),
          zoom: 17.0,
        ),
      ),
    );

    if (!_panelController.isPanelOpen) {
      _panelController.open();
    }

    _filterVisibleRestaurants();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${restaurant.name} 선택됨', style: TextStyle(fontSize: 14.sp)),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildTopSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '장소·지하철·지역명 검색 (주소 검색 준비 중 🙏)',
          hintStyle: TextStyle(
            fontSize: 14.sp,
            color: AppColors.mutedForeground,
          ),
          prefixIcon: Icon(Icons.search, color: AppColors.mutedForeground, size: 24.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: const Color(0xFF34A853),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category ||
              (_selectedCategory == null && category == '전체');

          return Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (category == '전체') {
                    _selectedCategory = null;
                  } else {
                    _selectedCategory = category;
                  }
                });
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border(bottom: BorderSide(color: Colors.white, width: 3))
                      : null,
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
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
            color: _isSearching ? Colors.grey[600] : const Color(0xFF34A853),
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
    });

    try {
      await _updateVisibleArea();

      print('🔍 화면 중심에서 검색 시작: lat=$_currentMapCenterLat, lng=$_currentMapCenterLng');

      final latDiff = _mapNorthLatitude - _mapSouthLatitude;
      final radiusInKm = (latDiff * 111.0) / 2;
      final radiusInMeters = (radiusInKm * 1000).toInt().clamp(500, 20000);

      print('📐 검색 반경: ${radiusInMeters}m (화면 기반)');

      final allRestaurants = <RestaurantModel>[];
      int pageCount = 0;

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
        color: isSelected ? const Color(0xFF34A853) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isSelected ? const Color(0xFF34A853) : Colors.grey[300]!,
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
    );
  }
}
