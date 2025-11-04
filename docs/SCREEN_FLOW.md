# 화면 흐름도 및 상세 설계

> 📱 **오점너** 앱의 전체 화면 흐름과 각 화면의 상세 구성

## 🗺️ 전체 화면 흐름도

```
[스플래시 화면]
    ↓
[온보딩 1/2/3] (첫 실행만)
    ↓
[로그인/회원가입 선택]
    ├─→ [Google/Apple/Kakao 로그인] → [홈 화면]
    ├─→ [이메일 로그인] ↔ [이메일 회원가입] → [홈 화면]
    └─→ [비회원 경고 팝업] → [비회원 모드] → [홈 화면]
    ↓
[위치 권한 요청]
    ↓
[홈 화면] (회원 / 비회원)
    ├─→ [슬롯머신] → [돌리는 중] → [결과]
    │       ├─→ [Naver Map에서 보기]
    │       └─→ [✓ 방문 완료] (자동 저장)
    │
    ├─→ [지도] → 식당 리스트
    │       ├─→ [Naver Map에서 보기]
    │       └─→ [✓ 방문 완료] (자동 저장)
    │
    ├─→ [방문 기록] ↔ [방문 기록 지도]
    │
    └─→ [설정]
```

## 📱 화면 상세 설계

### 1. 스플래시 화면

**구성 요소:**
- 앱 로고 (중앙)
- 앱 이름: "오점너"
- 서브 타이틀: "오늘 점심은 너야!"
- 로딩 인디케이터 (하단)

**Material Icons:**
- 로딩: `Icons.refresh` (회전 애니메이션)

**표시 시간:** 2-3초

---

### 2. 온보딩 (1/2/3)

**화면 1: 환영**
- 타이틀: "오점너에 오신 것을 환영합니다!"
- 설명: "매일 점심 고민? 이제 3초만에 해결!"
- 페이지 인디케이터: ○ ○ ●

**화면 2: 기능 소개**
- 슬롯머신 기능 설명
- Material Icon: `Icons.casino`

**화면 3: 시작**
- 지도 기능 설명
- Material Icon: `Icons.map`
- 버튼: [건너뛰기] [시작하기 →]

---

### 3. 로그인/회원가입 선택

**구성 요소:**
```dart
Column(
  children: [
    // 로고
    Icon(Icons.restaurant_menu, size: 80),
    Text('오점너'),
    Text('오늘 점심은 너야!'),
    
    // 소셜 로그인 버튼
    SocialLoginButton(
      icon: Icons.g_mobiledata,  // Google
      text: 'Google로 계속하기',
    ),
    SocialLoginButton(
      icon: Icons.apple,  // Apple
      text: 'Apple로 계속하기',
    ),
    SocialLoginButton(
      icon: Icons.chat_bubble,  // Kakao
      text: 'Kakao로 계속하기',
      color: Color(0xFFFEE500),
    ),
    
    // 이메일 로그인
    TextButton(
      child: Text('이메일로 계속하기'),
      icon: Icon(Icons.email),
    ),
    
    // 비회원 진행
    TextButton(
      child: Text('회원가입 없이 진행하기'),
      icon: Icon(Icons.arrow_forward),
    ),
  ],
)
```

---

### 4. 비회원 경고 팝업

**Dialog 구성:**
```dart
AlertDialog(
  icon: Icon(Icons.warning, color: Colors.orange),
  title: Text('회원가입 없이 진행?'),
  content: Column(
    children: [
      Text('회원가입을 하지 않으면'),
      Text('다녀온 데이터는 3주만 보관됩니다.'),
      Text('3주 이후 데이터는 자동으로 삭제됩니다.'),
    ],
  ),
  actions: [
    TextButton(
      child: Text('그래도 진행하기'),
    ),
    ElevatedButton(
      child: Text('회원가입하기'),
    ),
  ],
)
```

---

### 5. 위치 권한 요청

**구성 요소:**
```dart
Center(
  child: Column(
    children: [
      Icon(Icons.location_on, size: 80),
      Text('위치 권한이 필요해요'),
      Text('주변 식당을 추천하기 위해'),
      Text('현재 위치 정보가 필요합니다'),
      
      // 권한 설명
      ListTile(
        leading: Icon(Icons.check_circle),
        title: Text('현재 위치 기반 식당 검색'),
      ),
      ListTile(
        leading: Icon(Icons.check_circle),
        title: Text('거리 계산'),
      ),
      ListTile(
        leading: Icon(Icons.check_circle),
        title: Text('지도 표시'),
      ),
      
      ElevatedButton(
        child: Text('허용하기'),
      ),
      TextButton(
        child: Text('나중에 설정하기'),
      ),
    ],
  ),
)
```

---

### 6. 홈 화면 (회원)

**AppBar:**
```dart
AppBar(
  title: Column(
    children: [
      Text('오늘 점심'),
      Text('뭐 먹을까요?', style: TextStyle(fontSize: 12)),
    ],
  ),
  actions: [
    IconButton(icon: Icon(Icons.notifications)),
    IconButton(icon: Icon(Icons.settings)),
  ],
)
```

**Body:**
```dart
Column(
  children: [
    // 날씨 카드
    WeatherCard(
      icon: Icons.wb_sunny,
      temperature: '18°C',
      condition: '맑음',
      message: '오늘 같은 날엔...\n시원한 냉면 어때요?',
    ),
    
    // 슬롯머신 버튼
    LargeActionButton(
      icon: Icons.casino,
      text: '오늘 점심 뽑기!',
      onTap: () => Navigator.push(SlotMachinePage()),
    ),
    
    // 지도 버튼
    ActionButton(
      icon: Icons.map,
      text: '지도에서 찾기',
      subtitle: '주변 식당 확인',
      onTap: () => Navigator.push(MapPage()),
    ),
    
    // 방문 기록 버튼
    ActionButton(
      icon: Icons.history,
      text: '방문 기록',
      subtitle: '내가 다녀온 식당',
      onTap: () => Navigator.push(HistoryPage()),
    ),
  ],
)
```

**BottomNavigationBar:**
```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: '홈',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.map),
      label: '지도',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: '기록',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: '설정',
    ),
  ],
)
```

---

### 7. 홈 화면 (비회원 - 3주 경고 배너)

**추가 배너:**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.orange.withOpacity(0.1),
    border: Border.all(color: Colors.orange),
    borderRadius: BorderRadius.circular(radiusLg),
  ),
  child: Row(
    children: [
      Icon(Icons.warning, color: Colors.orange),
      Column(
        children: [
          Text('비회원 모드'),
          Text('데이터 삭제까지 18일 남음'),
        ],
      ),
      TextButton(
        child: Text('회원가입하기'),
        icon: Icon(Icons.arrow_forward),
      ),
    ],
  ),
)
```

---

### 8. 슬롯머신 화면

**구성:**
```dart
Column(
  children: [
    // 슬롯머신 아이콘
    Icon(Icons.casino, size: 80),
    Text('오늘의 점심을'),
    Text('추천받아보세요!'),
    
    // 거리 선택
    Row(
      children: [
        Icon(Icons.location_on),
        Text('거리 선택'),
      ],
    ),
    SegmentedButton(
      segments: [
        ButtonSegment(value: 100, label: Text('100m')),
        ButtonSegment(value: 500, label: Text('500m')),
        ButtonSegment(value: 1000, label: Text('1km')),
        ButtonSegment(value: 2000, label: Text('2km')),
      ],
    ),
    
    // 추천 정보
    Container(
      child: Column(
        children: [
          Text('"오"늘 "점"심은 "너"야!'),
          Icon(Icons.touch_app, size: 48),
          Row(
            children: [
              Icon(Icons.wb_sunny),
              Text('맑음 18°C'),
            ],
          ),
          Text('시원한 메뉴 추천중...'),
        ],
      ),
    ),
    
    // 광고 영역
    AdBanner(),
  ],
)
```

---

### 9. 슬롯머신 돌아가는 중

**애니메이션:**
```dart
Center(
  child: Column(
    children: [
      // 회전 애니메이션
      AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            children: [
              Icon(Icons.local_pizza, size: 60),
              Icon(Icons.ramen_dining, size: 60),
              Icon(Icons.lunch_dining, size: 60),
            ],
          );
        },
      ),
      
      Text('추천 중입니다...'),
      
      // 로딩 인디케이터
      Row(
        children: [
          Icon(Icons.hourglass_top),
          Icon(Icons.hourglass_top),
          Icon(Icons.hourglass_top),
        ],
      ),
    ],
  ),
)
```

---

### 10. 슬롯머신 결과 화면

**구성:**
```dart
Column(
  children: [
    Text('✨ 오늘은! ✨'),
    
    // 식당 카드
    Card(
      child: Column(
        children: [
          Icon(Icons.ramen_dining, size: 80),
          Text('맛있는 국수집', style: TextStyle(fontSize: 24)),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              Text('4.5'),
              Text('(128)'),
            ],
          ),
          Row(
            children: [
              Text('한식'),
              Text('·'),
              Icon(Icons.location_on, size: 16),
              Text('250m'),
            ],
          ),
          
          // 추천 이유
          Container(
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.wb_sunny),
                Text('날씨 기반 추천'),
              ],
            ),
          ),
          Text('"맑은 날엔 시원한 국수가 딱이야!"'),
        ],
      ),
    ),
    
    // 액션 버튼
    ElevatedButton.icon(
      icon: Icon(Icons.map),
      label: Text('Naver Map에서 보기'),
    ),
    ElevatedButton.icon(
      icon: Icon(Icons.check_circle),
      label: Text('방문 완료'),
    ),
    OutlinedButton.icon(
      icon: Icon(Icons.refresh),
      label: Text('다시 돌리기'),
    ),
  ],
)
```

---

### 11. 지도 화면

**구성:**
```dart
Stack(
  children: [
    // Naver Map
    NaverMap(
      onMapCreated: _onMapCreated,
      markers: _markers,
    ),
    
    // 상단 거리 선택
    Positioned(
      top: 16,
      right: 16,
      child: DropdownButton(
        value: 500,
        items: [
          DropdownMenuItem(value: 100, child: Text('100m')),
          DropdownMenuItem(value: 500, child: Text('500m')),
          DropdownMenuItem(value: 1000, child: Text('1km')),
          DropdownMenuItem(value: 2000, child: Text('2km')),
        ],
      ),
    ),
    
    // 하단 슬라이드업 패널
    DraggableScrollableSheet(
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radiusXl),
            ),
          ),
          child: Column(
            children: [
              // 핸들
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Text('주변 식당 12곳'),
              
              // 식당 리스트
              ListView.builder(
                controller: scrollController,
                itemBuilder: (context, index) {
                  return RestaurantListItem(
                    icon: Icons.location_on,
                    name: '맛있는국수',
                    rating: 4.5,
                    category: '한식',
                    distance: '250m',
                    onMapTap: () {},
                    onCheckTap: () {},
                  );
                },
              ),
            ],
          ),
        );
      },
    ),
  ],
)
```

---

### 12. 방문 기록 메인

**구성:**
```dart
Column(
  children: [
    // 통계 카드
    Card(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart),
              Text('이번 달 통계'),
            ],
          ),
          
          StatItem(
            icon: Icons.restaurant,
            label: '총 방문',
            value: '18회',
          ),
          StatItem(
            icon: Icons.new_releases,
            label: '새로운 식당',
            value: '3곳',
          ),
          StatItem(
            icon: Icons.repeat,
            label: '재방문',
            value: '15회',
          ),
          
          // 최애 카테고리
          Text('최애 카테고리'),
          RankItem(rank: 1, category: '한식', icon: Icons.ramen_dining, count: 7),
          RankItem(rank: 2, category: '일식', icon: Icons.lunch_dining, count: 5),
          RankItem(rank: 3, category: '양식', icon: Icons.local_pizza, count: 3),
          
          // 최애 식당
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber),
              Text('맛있는국수 (5회)'),
            ],
          ),
        ],
      ),
    ),
    
    ElevatedButton.icon(
      icon: Icon(Icons.map),
      label: Text('지도에서 보기'),
    ),
    
    // 최근 방문
    Text('📅 최근 방문'),
    
    VisitHistoryItem(
      date: '오늘',
      icon: Icons.ramen_dining,
      name: '맛있는국수',
      category: '한식',
      distance: '250m',
      visitCount: 5,
    ),
    VisitHistoryItem(
      date: '어제',
      icon: Icons.local_pizza,
      name: '피자천국',
      category: '양식',
      distance: '380m',
      visitCount: 1,
    ),
  ],
)
```

---

### 13. 방문 기록 지도 뷰

**마커 크기 규칙:**

| 방문 횟수 | 표시 | 크기 | 강조 |
|-----------|------|------|------|
| 1회 | 1 | 작음 | 기본 |
| 2-3회 | 2, 3 | 중간 | 중간 강조 |
| 4-5회 | 4, 5 | 크게 | 강조 |
| 6회 이상 | 5++ | 가장 큼 | 최대 강조 + ✨ |

```dart
Marker(
  markerId: MarkerId(restaurant.id),
  position: LatLng(restaurant.lat, restaurant.lng),
  icon: _getMarkerIcon(restaurant.visitCount),
  infoWindow: InfoWindow(
    title: restaurant.name,
    snippet: '${restaurant.category} · ${restaurant.distance}m',
  ),
);
```

---

### 14. 설정 화면

**구성:**
```dart
ListView(
  children: [
    // 프로필
    ListTile(
      leading: Icon(Icons.person),
      title: Text('프로필'),
    ),
    Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text('홍길동'),
        subtitle: Text('gildong@example.com'),
        trailing: Icon(Icons.arrow_forward_ios),
      ),
    ),
    
    // 추천 설정
    ListTile(
      leading: Icon(Icons.tune),
      title: Text('추천 설정'),
    ),
    
    Text('기본 검색 반경'),
    SegmentedButton(
      segments: [
        ButtonSegment(value: 100, label: Text('100m')),
        ButtonSegment(value: 500, label: Text('500m')),
        ButtonSegment(value: 1000, label: Text('1km')),
        ButtonSegment(value: 2000, label: Text('2km')),
      ],
    ),
    
    Text('선호 음식 카테고리'),
    Wrap(
      children: [
        FilterChip(
          avatar: Icon(Icons.ramen_dining),
          label: Text('한식'),
          selected: true,
        ),
        FilterChip(
          avatar: Icon(Icons.lunch_dining),
          label: Text('일식'),
          selected: true,
        ),
        FilterChip(
          avatar: Icon(Icons.restaurant),
          label: Text('중식'),
          selected: false,
        ),
        FilterChip(
          avatar: Icon(Icons.local_pizza),
          label: Text('양식'),
          selected: false,
        ),
      ],
    ),
    
    // 알림
    SwitchListTile(
      secondary: Icon(Icons.notifications),
      title: Text('점심 시간 알림'),
      value: true,
      onChanged: (value) {},
    ),
    SwitchListTile(
      secondary: Icon(Icons.campaign),
      title: Text('새로운 추천 알림'),
      value: false,
      onChanged: (value) {},
    ),
    
    // 앱 정보
    ListTile(
      leading: Icon(Icons.info),
      title: Text('앱 정보'),
    ),
    ListTile(title: Text('버전 정보'), trailing: Text('1.0.0')),
    ListTile(title: Text('공지사항')),
    ListTile(title: Text('이용약관')),
    ListTile(title: Text('개인정보처리방침')),
    ListTile(title: Text('문의하기')),
    
    // 로그아웃
    ListTile(
      leading: Icon(Icons.logout),
      title: Text('로그아웃'),
    ),
    ListTile(
      leading: Icon(Icons.delete_forever),
      title: Text('회원 탈퇴'),
      textColor: Colors.red,
    ),
  ],
)
```

## 🔄 방문 완료 자동 저장 로직

```dart
// 방문 완료 버튼 클릭 시
Future<void> onVisitComplete(String restaurantId) async {
  try {
    // 1. 현재 날짜/시간으로 자동 저장
    final visit = Visit(
      restaurantId: restaurantId,
      visitedAt: DateTime.now(),
    );
    
    // 2. API 호출
    final response = await visitRepository.addVisit(visit);
    
    // 3. Toast 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('방문 기록이 저장되었습니다!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    // 4. 방문 횟수 자동 증가
    setState(() {
      visitCount++;
    });
    
  } catch (e) {
    // 에러 처리
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Text('저장에 실패했습니다. 다시 시도해주세요.'),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

**버튼 상태 관리:**
```dart
// 미방문 상태
ElevatedButton.icon(
  icon: Icon(Icons.check_circle),
  label: Text('방문 완료'),
  onPressed: () => onVisitComplete(restaurantId),
)

// 방문 완료 상태
ElevatedButton.icon(
  icon: Icon(Icons.check_circle),
  label: Text('방문함'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.grey,
    foregroundColor: Colors.white,
  ),
  onPressed: null,  // 비활성화
)
```

## 📊 총 화면 개수

| 카테고리 | 화면 수 | 화면 목록 |
|----------|---------|-----------|
| **인증/온보딩** | 5개 | 스플래시, 온보딩 3개, 로그인/회원가입 선택 |
| **권한** | 2개 | 비회원 경고, 위치 권한 요청 |
| **메인 기능** | 6개 | 홈(회원), 홈(비회원), 슬롯머신, 돌리는 중, 결과, 지도 |
| **방문 기록** | 2개 | 방문 기록 메인, 방문 기록 지도 |
| **설정** | 1개 | 설정 |
| **총계** | **17개** | - |

## 🎨 디자인 일관성 체크리스트

각 화면 구현 시 반드시 확인:

- [ ] Material Icons만 사용 (Emoji 금지)
- [ ] global.css의 색상 변수 사용
- [ ] 정의된 Border Radius 사용
- [ ] 정의된 Spacing 사용
- [ ] 정의된 Shadow 스타일 사용
- [ ] 정의된 Font Size 사용
- [ ] 친근한 메시지 톤 사용
- [ ] 일관된 버튼 스타일
- [ ] 일관된 카드 스타일
- [ ] 일관된 입력 필드 스타일
