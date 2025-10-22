# UI 디자인 규칙 및 가이드

> 🎨 **오점너** 앱의 모든 UI는 이 규칙을 반드시 따라야 합니다.

## 📐 핵심 디자인 원칙

### 1. 아이콘 사용 규칙

#### ❌ 절대 금지: Emoji 사용
```dart
// ❌ 잘못된 예시
Text('🍕 피자집')
Icon(Icons.emoji_food_beverage)

// ✅ 올바른 예시  
Icon(Icons.restaurant)
Icon(Icons.local_pizza)
```

#### ✅ 필수: Material Icons 사용
- Flutter의 `Icons` 클래스 사용
- Material Design 3 아이콘 세트 준수
- 일관된 아이콘 크기 유지

**주요 화면별 Material Icons 매핑:**

| 화면/기능 | Emoji (금지) | Material Icon (사용) |
|-----------|-------------|---------------------|
| 식당/음식 | 🍽️ | Icons.restaurant |
| 날씨 (맑음) | ☀️ | Icons.wb_sunny |
| 날씨 (흐림) | ☁️ | Icons.cloud |
| 날씨 (비) | 🌧️ | Icons.water_drop |
| 지도 | 🗺️ | Icons.map |
| 위치 | 📍 | Icons.location_on |
| 슬롯머신 | 🎰 | Icons.casino |
| 기록 | 📋 | Icons.history |
| 통계 | 📊 | Icons.bar_chart |
| 설정 | ⚙️ | Icons.settings |
| 알림 | 🔔 | Icons.notifications |
| 검색 | 🔍 | Icons.search |
| 홈 | 🏠 | Icons.home |
| 체크 완료 | ✅ | Icons.check_circle |
| 경고 | ⚠️ | Icons.warning |

### 2. 색상 시스템

모든 색상은 `.claude/global.css`에 정의된 CSS 변수를 사용합니다.

#### Light Mode 주요 색상

```dart
// Primary Color (오렌지 계열)
Color primaryColor = Color(0xFFFF8844);  // oklch(0.7040 0.1910 22.2160)

// Background
Color backgroundColor = Color(0xFFFFFFFF);  // oklch(1 0 0)

// Card
Color cardColor = Color(0xFFFFFFFF);  // oklch(1 0 0)

// Text
Color foregroundColor = Color(0xFF252525);  // oklch(0.1450 0 0)
Color mutedForegroundColor = Color(0xFF8E8E8E);  // oklch(0.5560 0 0)

// Border
Color borderColor = Color(0xFFEBEBEB);  // oklch(0.9220 0 0)
```

#### Dark Mode 주요 색상

```dart
// Background (Dark)
Color backgroundColorDark = Color(0xFF252525);  // oklch(0.1450 0 0)

// Foreground (Dark)
Color foregroundColorDark = Color(0xFFFBFBFB);  // oklch(0.9850 0 0)

// Card (Dark)
Color cardColorDark = Color(0xFF343434);  // oklch(0.2050 0 0)
```

### 3. 타이포그래피

```dart
// Font Family
const String fontFamily = 'Pretendard'; // or 'Noto Sans KR'

// Font Sizes
const double fontSizeSmall = 12.0;
const double fontSizeBase = 14.0;
const double fontSizeMedium = 16.0;
const double fontSizeLarge = 18.0;
const double fontSizeXLarge = 20.0;
const double fontSizeTitle = 24.0;

// Font Weights
const FontWeight fontWeightRegular = FontWeight.w400;
const FontWeight fontWeightMedium = FontWeight.w500;
const FontWeight fontWeightSemiBold = FontWeight.w600;
const FontWeight fontWeightBold = FontWeight.w700;
```

### 4. 그림자 (Shadow)

```dart
// Shadow Definitions
BoxShadow shadow2xs = BoxShadow(
  color: Colors.black.withOpacity(0.05),
  offset: Offset(0, 1),
  blurRadius: 3,
);

BoxShadow shadowSm = BoxShadow(
  color: Colors.black.withOpacity(0.10),
  offset: Offset(0, 1),
  blurRadius: 3,
  spreadRadius: 0,
);

BoxShadow shadowMd = BoxShadow(
  color: Colors.black.withOpacity(0.10),
  offset: Offset(0, 2),
  blurRadius: 4,
  spreadRadius: -1,
);

BoxShadow shadowLg = BoxShadow(
  color: Colors.black.withOpacity(0.10),
  offset: Offset(0, 4),
  blurRadius: 6,
  spreadRadius: -1,
);
```

### 5. Border Radius

```dart
// Radius Values (from CSS)
const double radiusSm = 6.0;   // calc(0.625rem - 4px)
const double radiusMd = 8.0;   // calc(0.625rem - 2px)
const double radiusLg = 10.0;  // 0.625rem
const double radiusXl = 14.0;  // calc(0.625rem + 4px)
```

### 6. Spacing

```dart
// Spacing System (0.25rem = 4px)
const double spacing1 = 4.0;   // var(--spacing) * 1
const double spacing2 = 8.0;   // var(--spacing) * 2
const double spacing3 = 12.0;  // var(--spacing) * 3
const double spacing4 = 16.0;  // var(--spacing) * 4
const double spacing5 = 20.0;  // var(--spacing) * 5
const double spacing6 = 24.0;  // var(--spacing) * 6
const double spacing8 = 32.0;  // var(--spacing) * 8
```

## 🖼️ 화면별 구현 가이드

### 홈 화면

```dart
// 날씨 카드
Container(
  decoration: BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusLg),
    boxShadow: [shadowMd],
  ),
  child: Row(
    children: [
      Icon(Icons.wb_sunny, size: 32),  // ☀️ 대신
      Text('맑음 18°C'),
    ],
  ),
);

// 슬롯머신 버튼
ElevatedButton.icon(
  icon: Icon(Icons.casino),  // 🎰 대신
  label: Text('오늘 점심 뽑기!'),
  style: ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLg),
    ),
  ),
);
```

### 지도 화면

```dart
// 위치 마커
Icon(Icons.location_on, color: Colors.red)  // 📍 대신

// 지도 아이콘
Icon(Icons.map)  // 🗺️ 대신
```

### 슬롯머신 화면

```dart
// 슬롯머신 아이콘
Icon(Icons.casino, size: 64)  // 🎰 대신

// 음식 아이콘들
Icon(Icons.restaurant)      // 🍽️ 대신
Icon(Icons.local_pizza)     // 🍕 대신
Icon(Icons.ramen_dining)    // 🍜 대신
Icon(Icons.lunch_dining)    // 🍱 대신
```

### 방문 기록 화면

```dart
// 통계 아이콘
Icon(Icons.bar_chart)  // 📊 대신

// 기록 아이콘
Icon(Icons.history)  // 📋 대신

// 체크 완료
Icon(Icons.check_circle, color: Colors.green)  // ✅ 대신
```

## 📝 친근한 메시지 톤

### 홈 화면 메시지
```dart
'오늘 점심 뭐 먹을까요?'
'배고프면 일도 안 되지! 빨리 골라볼까?'
```

### 슬롯머신 메시지
```dart
'오늘의 점심을 추천받아보세요!'
'두근두근... 어디가 나올까?'
'오늘의 행운이 당신을 기다려요!'
```

### 에러 메시지
```dart
'앗! 잠깐 문제가 생겼어요'
'인터넷 연결을 확인해주세요!'
'위치 정보를 켜주시면 더 정확해요!'
```

## 🎯 컴포넌트 스타일 가이드

### 버튼

```dart
// Primary Button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(
      horizontal: spacing6,
      vertical: spacing4,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLg),
    ),
    elevation: 2,
  ),
  child: Text('버튼 텍스트'),
);

// Secondary Button
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: BorderSide(color: borderColor, width: 2),
    padding: EdgeInsets.symmetric(
      horizontal: spacing6,
      vertical: spacing4,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLg),
    ),
  ),
  child: Text('버튼 텍스트'),
);
```

### 카드

```dart
Card(
  color: cardColor,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radiusLg),
  ),
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radiusLg),
      boxShadow: [shadowMd],
    ),
    padding: EdgeInsets.all(spacing4),
    child: Column(
      children: [
        // 카드 내용
      ],
    ),
  ),
);
```

### 입력 필드

```dart
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: mutedColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    contentPadding: EdgeInsets.all(spacing4),
  ),
);
```

## 🚫 금지 사항

### ❌ 절대 하지 말 것

1. **Emoji 사용 금지**
   ```dart
   // ❌ 금지
   Text('🍕'), Icon('🎰'), '☀️'
   
   // ✅ 사용
   Icon(Icons.local_pizza), Icon(Icons.casino), Icon(Icons.wb_sunny)
   ```

2. **하드코딩된 색상 금지**
   ```dart
   // ❌ 금지
   Color(0xFF123456)
   Colors.orange
   
   // ✅ 사용
   primaryColor  // 테마에서 정의된 색상
   Theme.of(context).colorScheme.primary
   ```

3. **임의의 폰트 크기 금지**
   ```dart
   // ❌ 금지
   TextStyle(fontSize: 17.3)
   
   // ✅ 사용
   TextStyle(fontSize: fontSizeMedium)  // 16.0
   ```

## ✅ 체크리스트

개발 시 아래 항목들을 반드시 확인하세요:

- [ ] 모든 아이콘이 Material Icons인가?
- [ ] Emoji를 사용하지 않았는가?
- [ ] 색상이 테마에서 정의된 값을 사용하는가?
- [ ] Border radius가 정의된 값을 사용하는가?
- [ ] Spacing이 일관된 시스템을 따르는가?
- [ ] 그림자가 정의된 스타일을 사용하는가?
- [ ] 폰트가 지정된 크기와 무게를 사용하는가?
- [ ] 메시지 톤이 친근한가?

## 📚 참고 자료

- [Material Icons 공식 문서](https://fonts.google.com/icons)
- [Material Design 3](https://m3.material.io/)
- [Flutter Material Components](https://docs.flutter.dev/ui/widgets/material)
