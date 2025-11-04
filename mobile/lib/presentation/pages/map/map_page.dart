import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
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
  NaverMapController? _mapController;
  final PanelController panelController = PanelController();

  List<RestaurantModel> _restaurants = [];
  RestaurantModel? _selectedRestaurant;

  bool _isLoadingLocation = false;
  bool _dialogShown = false;
  bool _isMapReady = false;
  bool _showLocationButton = true;
  bool _isSearching = false;

  final _googlePlacesService = GooglePlacesService();

  // 지도 중심 좌표
  double _currentMapCenterLat = 37.6161;
  double _currentMapCenterLng = 126.7168;

  // 카테고리
  String? _selectedCategory;
  final List<Map<String, String>> _categories = [
    {'name': '전체', 'type': 'restaurant'},
    {'name': '음식점', 'type': 'restaurant'},
    {'name': '카페', 'type': 'cafe'},
    {'name': '베이커리', 'type': 'bakery'},
    {'name': '술집', 'type': 'bar'},
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('🚀 MapPageNaver initState 시작');

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionAndShowDialog();

    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
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
        print('🔄 앱 재개 - 권한 있음');
        setState(() {
          _showLocationButton = true;
        });
      }
    }
  }

  Future<void> _checkPermissionAndShowDialog() async {
    print('🔍 권한 확인 시작');
    await ref.read(locationProvider.notifier).checkPermission();

    final locationState = ref.read(locationProvider);

    if (locationState.needsPermission && !_dialogShown && mounted) {
      _dialogShown = true;
      await _showPermissionDialog();
    }
  }

  Future<void> _showPermissionDialog() async {
    final locationState = ref.read(locationProvider);

    await LocationPermissionDialog.show(
      context,
      isPermanentlyDenied: locationState.isPermanentlyDenied,
      onDeny: () {
        Navigator.of(context).pop();
        _dialogShown = false;
      },
      onAllow: () async {
        Navigator.of(context).pop();
        await _handlePermissionAllow();
      },
    );
  }

  Future<void> _handlePermissionAllow() async {
    final locationNotifier = ref.read(locationProvider.notifier);
    final currentState = ref.read(locationProvider);

    if (currentState.isPermanentlyDenied) {
      await locationNotifier.openSettings();
      _dialogShown = false;
    } else {
      final result = await locationNotifier.requestPermission();

      if (result == LocationPermission.always ||
          result == LocationPermission.whileInUse) {
        await _moveToCurrentLocation();
      }
      _dialogShown = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // 네이버 지도
          NaverMap(
            onMapReady: _onMapReady,
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(_currentMapCenterLat, _currentMapCenterLng),
                zoom: 15,
              ),
              locationButtonEnable: false,
              rotationGesturesEnable: true,
              scrollGesturesEnable: true,
              tiltGesturesEnable: true,
              zoomGesturesEnable: true,
            ),
            onCameraChange: (reason, isAnimated) {},
            onCameraIdle: () {},
          ),

          // 상단 검색바 및 버튼
          Positioned(
            top: topPadding + 12.h,
            left: 16.w,
            right: 16.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFloatingSearchBar(),
                SizedBox(height: 12.h),
                if (!_isSearching)
                  ElevatedButton.icon(
                    onPressed: _searchRestaurantsAtCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.foreground,
                      elevation: 4,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                    icon: Icon(Icons.search, size: 20.sp),
                    label: Text(
                      '이 위치로 검색',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          '검색 중...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 우측 하단 내 위치 버튼
          if (_showLocationButton)
            Positioned(
              bottom: bottomPadding + 16.h,
              right: 16.w,
              child: FloatingActionButton(
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

  void _onMapReady(NaverMapController controller) async {
    print('🗺️ 네이버 지도 로드 완료');
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });

    await _moveToCurrentLocationIfPermitted();
  }

  Future<void> _moveToCurrentLocationIfPermitted() async {
    await ref.read(locationProvider.notifier).checkPermission();
    final locationState = ref.read(locationProvider);

    if (locationState.isGranted) {
      await _moveToCurrentLocation();
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
        _currentMapCenterLat = position.latitude;
        _currentMapCenterLng = position.longitude;

        await _mapController!.updateCamera(
          NCameraUpdate.scrollAndZoomTo(
            target: NLatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('현재 위치로 이동했습니다', style: TextStyle(fontSize: 14.sp)),
            duration: const Duration(seconds: 1),
            backgroundColor: AppColors.primary,
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
      ),
    );
  }

  Future<void> _searchRestaurantsAtCurrentLocation() async {
    setState(() {
      _isSearching = true;
      _selectedRestaurant = null;
      _showLocationButton = true;
    });

    try {
      print('🔍 Google Places API 검색 시작: lat=$_currentMapCenterLat, lng=$_currentMapCenterLng');

      final radiusInMeters = 1000; // 1km

      final selectedType = _selectedCategory != null
          ? _categories.firstWhere(
              (cat) => cat['name'] == _selectedCategory,
              orElse: () => _categories[0],
            )['type']!
          : 'restaurant';

      final allRestaurants = <RestaurantModel>[];
      String? nextPageToken;

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

          if (results.isEmpty) break;

          final restaurants = results
              .map((place) => RestaurantModel.fromGooglePlaces(
                    place as Map<String, dynamic>,
                    _currentMapCenterLat,
                    _currentMapCenterLng,
                  ))
              .toList();

          allRestaurants.addAll(restaurants);

          nextPageToken = response['next_page_token'] as String?;

          if (nextPageToken == null) break;

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

      // 네이버 지도에 마커 추가
      await _showRestaurantMarkersOnMap(allRestaurants);

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
                '${allRestaurants.length}곳 발견',
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

  Future<void> _showRestaurantMarkersOnMap(List<RestaurantModel> restaurants) async {
    if (!_isMapReady || _mapController == null) return;

    try {
      // 기존 마커 제거
      await _mapController!.clearOverlays(type: NOverlayType.marker);

      // 새 마커 추가
      final overlays = restaurants.map<NAddableOverlay>((restaurant) {
        final marker = NMarker(
          id: 'restaurant_${restaurant.id}',
          position: NLatLng(restaurant.latitude, restaurant.longitude),
        );
        marker.setOnTapListener((_) {
          setState(() {
            _selectedRestaurant = restaurant;
            _showLocationButton = false;
          });

          _mapController?.updateCamera(
            NCameraUpdate.scrollAndZoomTo(
              target: NLatLng(restaurant.latitude, restaurant.longitude),
            ),
          );
        });
        return marker;
      }).toSet();

      await _mapController!.addOverlayAll(overlays);
      print('✅ ${overlays.length}개 마커 추가 완료');
    } catch (e) {
      print('❌ 마커 표시 중 오류: $e');
    }
  }

  void _showPlaceDetails(RestaurantModel restaurant) {
    final detailsFuture = _googlePlacesService.getPlaceDetails(placeId: restaurant.id);

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
          return FutureBuilder<Map<String, dynamic>>(
            future: detailsFuture,
            builder: (context, snapshot) {
              RestaurantModel displayRestaurant = restaurant;
              if (snapshot.hasData) {
                final result = snapshot.data!['result'] as Map<String, dynamic>?;
                if (result != null) {
                  displayRestaurant = RestaurantModel.fromPlaceDetails(
                    result,
                    _currentMapCenterLat,
                    _currentMapCenterLng,
                  );
                }
              }

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
                        displayRestaurant.name,
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
                              displayRestaurant.category,
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
                            displayRestaurant.distanceText,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      // 평점
                      if (displayRestaurant.rating > 0)
                        Row(
                          children: [
                            Icon(Icons.star, size: 20.sp, color: Colors.amber),
                            SizedBox(width: 4.w),
                            Text(
                              displayRestaurant.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 16.sp,
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

                      SizedBox(height: 24.h),

                      // 액션 버튼
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: Icon(Icons.close, size: 20.sp),
                              label: Text('닫기', style: TextStyle(fontSize: 16.sp)),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
