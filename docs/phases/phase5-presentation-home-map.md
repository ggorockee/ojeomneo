# Phase 5: Presentation 레이어 - 홈/지도 화면

> 🎯 **목표**: 홈 화면과 지도 화면 UI 구현

## 📋 작업 목록

### 5.1 Riverpod Providers 설정
- [ ] `lib/presentation/providers/location_provider.dart` 생성
  - [ ] 현재 위치 Provider
  - [ ] 위치 권한 상태 Provider
  - [ ] StateNotifier로 위치 업데이트
- [ ] `lib/presentation/providers/weather_provider.dart` 생성
  - [ ] 날씨 정보 Provider
  - [ ] FutureProvider로 날씨 데이터 로드
- [ ] `lib/presentation/providers/restaurant_provider.dart` 생성
  - [ ] 식당 목록 Provider
  - [ ] 거리 필터 Provider
  - [ ] 선택된 거리 상태 (100m/500m/1000m)

### 5.2 홈 화면 (Home Page)
- [ ] `lib/presentation/pages/home/home_page.dart` 생성
  - [ ] AppBar 구현
    - [ ] 타이틀: "오점너"
    - [ ] 위치 정보 표시
  - [ ] 날씨 정보 카드 위젯
    - [ ] 현재 온도 표시
    - [ ] 날씨 아이콘
    - [ ] 날씨 설명 (친근한 메시지)
  - [ ] 슬롯머신 버튼
    - [ ] 큰 원형 버튼
    - [ ] "오늘 점심 뭐 먹을래? 🎰" 텍스트
    - [ ] 탭 시 슬롯머신 화면으로 이동
  - [ ] 지도 보기 버튼
    - [ ] "근처 맛집 보기 🗺️" 텍스트
    - [ ] 탭 시 지도 화면으로 이동
  - [ ] 방문 기록 버튼
    - [ ] "내 방문 기록 📝" 텍스트
    - [ ] 탭 시 히스토리 화면으로 이동

### 5.3 홈 화면 위젯
- [ ] `lib/presentation/widgets/weather_card.dart` 생성
  - [ ] 날씨 정보 표시 카드
  - [ ] 온도, 습도, 날씨 상태 표시
  - [ ] 그라데이션 배경 (날씨에 따라 변경)
  - [ ] 애니메이션 효과
- [ ] `lib/presentation/widgets/action_button.dart` 생성
  - [ ] 재사용 가능한 액션 버튼
  - [ ] 아이콘, 텍스트, onTap 콜백
  - [ ] 그림자 효과
  - [ ] 탭 애니메이션

### 5.4 지도 화면 (Map Page)
- [ ] `lib/presentation/pages/map/map_page.dart` 생성
  - [ ] Naver Map 위젯 통합
  - [ ] 현재 위치 마커 표시
  - [ ] 식당 마커 표시
  - [ ] 거리 선택 드롭다운
    - [ ] 100m / 500m / 1000m 옵션
    - [ ] 선택 시 식당 목록 업데이트
  - [ ] 하단 슬라이드업 패널
    - [ ] 식당 목록 표시
    - [ ] 스크롤 가능한 리스트
- [ ] `lib/presentation/pages/map/map_controller.dart` 생성
  - [ ] 지도 컨트롤러 로직
  - [ ] 마커 관리
  - [ ] 카메라 이동

### 5.5 지도 화면 위젯
- [ ] `lib/presentation/widgets/distance_dropdown.dart` 생성
  - [ ] 거리 선택 드롭다운
  - [ ] 100m, 500m, 1000m 옵션
  - [ ] 선택 시 Provider 업데이트
- [ ] `lib/presentation/widgets/restaurant_list_item.dart` 생성
  - [ ] 식당 정보 카드
  - [ ] 식당 이름, 카테고리, 거리
  - [ ] 썸네일 이미지
  - [ ] 탭 시 상세 화면으로 이동
- [ ] `lib/presentation/widgets/slide_up_panel.dart` 생성
  - [ ] 하단에서 올라오는 패널
  - [ ] 드래그로 높이 조절
  - [ ] 식당 목록 표시

### 5.6 라우팅 설정
- [ ] `lib/presentation/routes/app_routes.dart` 생성
  - [ ] 라우트 이름 상수 정의
  - [ ] `/home` - 홈 화면
  - [ ] `/map` - 지도 화면
  - [ ] `/slot-machine` - 슬롯머신 화면
  - [ ] `/history` - 방문 기록 화면
- [ ] `lib/presentation/routes/app_router.dart` 생성
  - [ ] MaterialPageRoute 설정
  - [ ] 화면 전환 애니메이션

### 5.7 앱 진입점 수정
- [ ] `lib/app.dart` 생성
  - [ ] MaterialApp 설정
  - [ ] 테마 적용
  - [ ] 초기 라우트 설정
  - [ ] ProviderScope 래핑
- [ ] `lib/main.dart` 수정
  - [ ] 환경 변수 초기화
  - [ ] Hive 초기화
  - [ ] ProviderScope 추가
  - [ ] MyApp 실행

## 📝 주요 파일

| 파일 경로 | 설명 |
|-----------|------|
| `lib/presentation/pages/home/home_page.dart` | 홈 화면 |
| `lib/presentation/pages/map/map_page.dart` | 지도 화면 |
| `lib/presentation/providers/restaurant_provider.dart` | 식당 Provider |
| `lib/app.dart` | 앱 진입점 |

## 🎯 완료 조건

- ✅ Riverpod Providers 설정 완료
- ✅ 홈 화면 UI 구현 완료
- ✅ 지도 화면 UI 구현 완료
- ✅ 라우팅 설정 완료
- ✅ 앱 진입점 설정 완료

## 🚀 다음 단계

Phase 6: Presentation 레이어 (슬롯머신/히스토리) 구현으로 이동

## 🎨 UI 디자인 규칙 준수

### ⚠️ 필수 규칙

#### 1. Material Icons 사용 (Emoji 금지)

```dart
// ❌ 잘못된 예시
Text('🎰 오늘 점심 뭐 먹을래?')
Icon(Icons.emoji_food_beverage)

// ✅ 올바른 예시
Row(
  children: [
    Icon(Icons.casino),
    Text('오늘 점심 뭐 먹을래?'),
  ],
)
```

**홈 화면 아이콘 매핑:**
- 슬롯머신: `Icons.casino` (🎰 대신)
- 지도: `Icons.map` (🗺️ 대신)
- 방문 기록: `Icons.history` (📝 대신)
- 날씨(맑음): `Icons.wb_sunny` (☀️ 대신)
- 날씨(흐림): `Icons.cloud` (☁️ 대신)
- 날씨(비): `Icons.water_drop` (🌧️ 대신)
- 알림: `Icons.notifications` (🔔 대신)
- 설정: `Icons.settings` (⚙️ 대신)

**지도 화면 아이콘 매핑:**
- 위치 마커: `Icons.location_on` (📍 대신)
- 현재 위치: `Icons.my_location`
- 식당: `Icons.restaurant`
- 체크 완료: `Icons.check_circle` (✅ 대신)

#### 2. 색상 시스템 (.claude/global.css 준수)

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  // Primary (오렌지 계열)
  static const primary = Color(0xFFFF8844);  // oklch(0.7040 0.1910 22.2160)
  
  // Background
  static const background = Color(0xFFFFFFFF);  // oklch(1 0 0)
  
  // Text
  static const foreground = Color(0xFF252525);  // oklch(0.1450 0 0)
  static const mutedForeground = Color(0xFF8E8E8E);  // oklch(0.5560 0 0)
  
  // Border
  static const border = Color(0xFFEBEBEB);  // oklch(0.9220 0 0)
}
```

#### 3. Border Radius 규칙

```dart
// lib/core/theme/app_dimensions.dart
class AppDimensions {
  static const double radiusSm = 6.0;   // small
  static const double radiusMd = 8.0;   // medium
  static const double radiusLg = 10.0;  // large
  static const double radiusXl = 14.0;  // extra large
}
```

#### 4. Spacing 시스템

```dart
class AppSpacing {
  static const double spacing1 = 4.0;   // 1x
  static const double spacing2 = 8.0;   // 2x
  static const double spacing3 = 12.0;  // 3x
  static const double spacing4 = 16.0;  // 4x
  static const double spacing6 = 24.0;  // 6x
  static const double spacing8 = 32.0;  // 8x
}
```

### 📱 화면별 구현 예시

#### 홈 화면 - 날씨 카드

```dart
Container(
  padding: EdgeInsets.all(AppSpacing.spacing4),
  decoration: BoxDecoration(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.10),
        offset: Offset(0, 2),
        blurRadius: 4,
        spreadRadius: -1,
      ),
    ],
  ),
  child: Column(
    children: [
      Row(
        children: [
          Icon(
            Icons.wb_sunny,  // ☀️ 대신
            size: 32,
            color: Colors.orange,
          ),
          SizedBox(width: AppSpacing.spacing2),
          Text(
            '맑음 18°C',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      SizedBox(height: AppSpacing.spacing2),
      Text(
        '오늘 같은 날엔...',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.mutedForeground,
        ),
      ),
      Row(
        children: [
          Icon(Icons.ramen_dining, size: 20),  // 🍜 대신
          SizedBox(width: AppSpacing.spacing1),
          Text('시원한 냉면 어때요?'),
        ],
      ),
    ],
  ),
)
```

#### 홈 화면 - 슬롯머신 버튼

```dart
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/slot-machine'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.spacing6,
      vertical: AppSpacing.spacing4,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    ),
    elevation: 2,
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.casino, size: 32),  // 🎰 대신
      SizedBox(width: AppSpacing.spacing2),
      Column(
        children: [
          Text(
            '오늘 점심 뽑기!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ],
  ),
)
```

#### 지도 화면 - 식당 리스트 아이템

```dart
ListTile(
  leading: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
    ),
    child: Icon(
      Icons.location_on,  // 📍 대신
      color: Colors.red,
    ),
  ),
  title: Row(
    children: [
      Text('맛있는국수'),
      SizedBox(width: AppSpacing.spacing1),
      Icon(Icons.star, size: 16, color: Colors.amber),  // ⭐ 대신
      Text('4.5'),
    ],
  ),
  subtitle: Row(
    children: [
      Text('한식'),
      Text(' · '),
      Icon(Icons.location_on, size: 12),
      Text('250m'),
    ],
  ),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(Icons.map),  // 🗺️ 대신
        onPressed: () {
          // Naver Map으로 열기
        },
      ),
      IconButton(
        icon: Icon(Icons.check_circle),  // ✅ 대신
        onPressed: () {
          // 방문 완료
        },
      ),
    ],
  ),
)
```

### 🔍 검증 체크리스트

Phase 5 구현 완료 전 반드시 확인:

- [ ] 모든 Emoji를 Material Icons로 교체
- [ ] AppColors 클래스의 색상 사용
- [ ] AppDimensions의 Border Radius 사용
- [ ] AppSpacing의 Spacing 사용
- [ ] 하드코딩된 색상 값 없음
- [ ] 하드코딩된 크기 값 최소화
- [ ] 일관된 그림자 스타일 적용
- [ ] 친근한 메시지 톤 유지

### 📚 참고 문서

- [UI 디자인 규칙 전체 문서](../UI_DESIGN_RULES.md)
- [화면 흐름도 및 상세 설계](../SCREEN_FLOW.md)
- [Material Icons 검색](https://fonts.google.com/icons)
