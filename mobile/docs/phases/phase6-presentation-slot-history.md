# Phase 6: Presentation 레이어 - 슬롯머신/히스토리 화면

> 🎯 **목표**: 슬롯머신 추천 화면과 방문 기록 화면 구현

## 📋 작업 목록

### 6.1 슬롯머신 Providers
- [ ] `lib/presentation/providers/recommendation_provider.dart` 생성
  - [ ] 추천 전략 Provider (날씨/거리/랜덤)
  - [ ] 추천 결과 Provider
  - [ ] 슬롯머신 애니메이션 상태
  - [ ] StateNotifier로 추천 로직 관리

### 6.2 슬롯머신 화면 (Slot Machine Page)
- [ ] `lib/presentation/pages/slot_machine/slot_machine_page.dart` 생성
  - [ ] AppBar 구현
    - [ ] 타이틀: "오늘의 추천"
    - [ ] 뒤로가기 버튼
  - [ ] 추천 전략 선택 버튼
    - [ ] 날씨 기반 추천 버튼
    - [ ] 거리 기반 추천 버튼
    - [ ] 랜덤 추천 버튼
  - [ ] Lottie 애니메이션 영역
    - [ ] 슬롯머신 애니메이션
    - [ ] 로딩 애니메이션
  - [ ] 추천 시작 버튼
    - [ ] "돌려돌려 돌림판! 🎰" 텍스트
    - [ ] 큰 원형 버튼
    - [ ] 탭 시 추천 시작
  - [ ] 추천 결과 카드
    - [ ] 식당 정보 표시
    - [ ] 추천 이유 표시
    - [ ] 지도에서 보기 버튼
    - [ ] 방문 기록 추가 버튼

### 6.3 슬롯머신 위젯
- [ ] `lib/presentation/widgets/strategy_selector.dart` 생성
  - [ ] 추천 전략 선택 위젯
  - [ ] 3개 버튼 (날씨/거리/랜덤)
  - [ ] 선택된 전략 하이라이트
  - [ ] 애니메이션 효과
- [ ] `lib/presentation/widgets/slot_machine_animation.dart` 생성
  - [ ] Lottie 애니메이션 래퍼
  - [ ] 애니메이션 재생/정지 제어
  - [ ] 애니메이션 완료 콜백
- [ ] `lib/presentation/widgets/recommendation_card.dart` 생성
  - [ ] 추천 결과 카드
  - [ ] 식당 이름, 카테고리
  - [ ] 추천 이유 (친근한 메시지)
  - [ ] 액션 버튼들
  - [ ] 등장 애니메이션

### 6.4 Lottie 애니메이션 통합
- [ ] Lottie 애니메이션 파일 추가
  - [ ] `assets/animations/slot_machine.json`
  - [ ] `assets/animations/loading.json`
  - [ ] pubspec.yaml에 assets 경로 추가
- [ ] 애니메이션 재생 로직
  - [ ] 추천 시작 시 재생
  - [ ] 추천 완료 시 정지
  - [ ] 반복 재생 설정

### 6.5 방문 기록 Providers
- [ ] `lib/presentation/providers/visit_history_provider.dart` 생성
  - [ ] 방문 기록 목록 Provider
  - [ ] 방문 통계 Provider
  - [ ] 방문 기록 추가/삭제 액션

### 6.6 방문 기록 화면 (History Page)
- [ ] `lib/presentation/pages/history/history_page.dart` 생성
  - [ ] AppBar 구현
    - [ ] 타이틀: "내 방문 기록"
    - [ ] 뒤로가기 버튼
  - [ ] 통계 대시보드 영역
    - [ ] 총 방문 횟수
    - [ ] 가장 좋아하는 카테고리
    - [ ] 최근 방문 날짜
  - [ ] 방문 기록 리스트
    - [ ] 날짜별 그룹핑
    - [ ] 식당 이름, 카테고리
    - [ ] 방문 날짜
    - [ ] 평가 (별점, 선택사항)
    - [ ] 메모 (선택사항)
  - [ ] 빈 상태 UI
    - [ ] "아직 방문 기록이 없어요 😊"
    - [ ] "식당을 방문하고 기록을 남겨보세요!"

### 6.7 방문 기록 위젯
- [ ] `lib/presentation/widgets/statistics_card.dart` 생성
  - [ ] 통계 정보 카드
  - [ ] 아이콘 + 숫자 + 설명
  - [ ] 그리드 레이아웃
- [ ] `lib/presentation/widgets/visit_history_item.dart` 생성
  - [ ] 방문 기록 아이템
  - [ ] 식당 정보 표시
  - [ ] 방문 날짜 포맷팅
  - [ ] 삭제 버튼
  - [ ] 스와이프 삭제 기능
- [ ] `lib/presentation/widgets/empty_state.dart` 생성
  - [ ] 빈 상태 UI
  - [ ] 이미지/아이콘
  - [ ] 친근한 메시지
  - [ ] 액션 버튼 (선택사항)

### 6.8 친근한 메시지 통합
- [ ] 슬롯머신 메시지
  - [ ] "두근두근... 어디가 나올까?"
  - [ ] "오늘의 행운이 당신을 기다려요!"
  - [ ] "짜잔! 여기 어때요?"
- [ ] 추천 이유 메시지
  - [ ] 날씨: "오늘 같은 날씨엔 이게 최고예요! ☀️"
  - [ ] 거리: "여기 바로 근처인데 맛있대요! 🚶"
  - [ ] 랜덤: "새로운 도전! 여기 가볼래요? 🎲"
- [ ] 방문 기록 메시지
  - [ ] "이번 달에 {count}번 방문했어요!"
  - [ ] "{category}을(를) 제일 좋아하시나봐요! 😋"

## 📝 주요 파일

| 파일 경로 | 설명 |
|-----------|------|
| `lib/presentation/pages/slot_machine/slot_machine_page.dart` | 슬롯머신 화면 |
| `lib/presentation/pages/history/history_page.dart` | 방문 기록 화면 |
| `lib/presentation/providers/recommendation_provider.dart` | 추천 Provider |

## 🎯 완료 조건

- ✅ 슬롯머신 화면 UI 구현 완료
- ✅ Lottie 애니메이션 통합 완료
- ✅ 방문 기록 화면 UI 구현 완료
- ✅ 통계 대시보드 구현 완료
- ✅ 친근한 메시지 통합 완료

## 🚀 다음 단계

Phase 7: 테스트 및 배포로 이동

## 🎨 UI 디자인 규칙 준수

### ⚠️ 필수 규칙

#### 1. Material Icons 사용 (Emoji 금지)

**슬롯머신 화면 아이콘 매핑:**
- 슬롯머신: `Icons.casino` (🎰 대신)
- 위치: `Icons.location_on` (📍 대신)
- 날씨(맑음): `Icons.wb_sunny` (☀️ 대신)
- 식당: `Icons.restaurant` (🍽️ 대신)
- 피자: `Icons.local_pizza` (🍕 대신)
- 라면: `Icons.ramen_dining` (🍜 대신)
- 도시락: `Icons.lunch_dining` (🍱 대신)
- 리프레시: `Icons.refresh` (🔄 대신)
- 체크: `Icons.check_circle` (✅ 대신)

**방문 기록 화면 아이콘 매핑:**
- 통계: `Icons.bar_chart` (📊 대신)
- 기록: `Icons.history` (📋 대신)
- 달력: `Icons.calendar_today` (📅 대신)
- 트로피: `Icons.emoji_events` (🏆 대신)
- 그룹: `Icons.group` (👥 대신)
- 신규: `Icons.new_releases` (🆕 대신)
- 반복: `Icons.repeat` (🔄 대신)

### 📱 화면별 구현 예시

#### 슬롯머신 화면 - 메인 UI

```dart
Column(
  children: [
    // 슬롯머신 아이콘
    Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.casino,  // 🎰 대신
        size: 64,
        color: AppColors.primary,
      ),
    ),
    SizedBox(height: AppSpacing.spacing4),
    Text(
      '오늘의 점심을',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    Text(
      '추천받아보세요!',
      style: TextStyle(fontSize: 16),
    ),
    
    // 거리 선택
    SizedBox(height: AppSpacing.spacing6),
    Row(
      children: [
        Icon(Icons.location_on),  // 📍 대신
        SizedBox(width: AppSpacing.spacing2),
        Text('거리 선택'),
      ],
    ),
    SegmentedButton<int>(
      segments: [
        ButtonSegment(value: 100, label: Text('100m')),
        ButtonSegment(value: 500, label: Text('500m')),
        ButtonSegment(value: 1000, label: Text('1km')),
        ButtonSegment(value: 2000, label: Text('2km')),
      ],
      selected: {selectedDistance},
      onSelectionChanged: (Set<int> newSelection) {
        setState(() {
          selectedDistance = newSelection.first;
        });
      },
    ),
  ],
)
```

#### 슬롯머신 - 돌아가는 애니메이션

```dart
// 애니메이션 중 표시되는 음식 아이콘들
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.local_pizza,  // 🍕 대신
          size: 60,
          color: AppColors.primary,
        ),
        SizedBox(height: AppSpacing.spacing2),
        Icon(
          Icons.ramen_dining,  // 🍜 대신
          size: 60,
          color: AppColors.primary,
        ),
        SizedBox(height: AppSpacing.spacing2),
        Icon(
          Icons.lunch_dining,  // 🍱 대신
          size: 60,
          color: AppColors.primary,
        ),
      ],
    );
  },
)
```

#### 슬롯머신 결과 화면

```dart
Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
  ),
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          offset: Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -1,
        ),
      ],
    ),
    padding: EdgeInsets.all(AppSpacing.spacing6),
    child: Column(
      children: [
        // 식당 아이콘
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.ramen_dining,  // 🍜 대신
            size: 48,
            color: AppColors.primary,
          ),
        ),
        
        SizedBox(height: AppSpacing.spacing3),
        
        Text(
          '맛있는 국수집',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // 평점
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, size: 20, color: Colors.amber),  // ⭐ 대신
            Text('4.5'),
            Text(' (128)'),
          ],
        ),
        
        // 카테고리 및 거리
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('한식'),
            Text(' · '),
            Icon(Icons.location_on, size: 16),  // 📍 대신
            Text('250m'),
          ],
        ),
        
        // 추천 이유
        Container(
          margin: EdgeInsets.symmetric(vertical: AppSpacing.spacing3),
          padding: EdgeInsets.all(AppSpacing.spacing3),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            children: [
              Icon(Icons.wb_sunny, color: Colors.orange),  // ☀️ 대신
              SizedBox(width: AppSpacing.spacing2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('날씨 기반 추천', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('"맑은 날엔 시원한 국수가 딱이야!"'),
                ],
              ),
            ],
          ),
        ),
        
        // 액션 버튼들
        ElevatedButton.icon(
          icon: Icon(Icons.map),  // 🗺️ 대신
          label: Text('Naver Map에서 보기'),
          onPressed: () {},
        ),
        SizedBox(height: AppSpacing.spacing2),
        ElevatedButton.icon(
          icon: Icon(Icons.check_circle),  // ✅ 대신
          label: Text('방문 완료'),
          onPressed: () {},
        ),
        SizedBox(height: AppSpacing.spacing2),
        OutlinedButton.icon(
          icon: Icon(Icons.refresh),  // 🔄 대신
          label: Text('다시 돌리기'),
          onPressed: () {},
        ),
      ],
    ),
  ),
)
```

#### 방문 기록 - 통계 카드

```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(AppSpacing.spacing4),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart),  // 📊 대신
            SizedBox(width: AppSpacing.spacing2),
            Text(
              '이번 달 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        SizedBox(height: AppSpacing.spacing3),
        
        // 통계 항목들
        _buildStatItem(
          icon: Icons.restaurant,
          label: '총 방문',
          value: '18회',
        ),
        _buildStatItem(
          icon: Icons.new_releases,
          label: '새로운 식당',
          value: '3곳',
        ),
        _buildStatItem(
          icon: Icons.repeat,
          label: '재방문',
          value: '15회',
        ),
        
        Divider(),
        
        // 최애 카테고리
        Text('최애 카테고리', style: TextStyle(fontWeight: FontWeight.bold)),
        _buildRankItem(
          rank: 1,
          category: '한식',
          icon: Icons.ramen_dining,  // 🍜 대신
          count: 7,
        ),
        _buildRankItem(
          rank: 2,
          category: '일식',
          icon: Icons.lunch_dining,  // 🍱 대신
          count: 5,
        ),
        _buildRankItem(
          rank: 3,
          category: '양식',
          icon: Icons.local_pizza,  // 🍕 대신
          count: 3,
        ),
        
        Divider(),
        
        // 최애 식당
        Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),  // 🏆 대신
            SizedBox(width: AppSpacing.spacing2),
            Text('맛있는국수 (5회)'),
          ],
        ),
      ],
    ),
  ),
)
```

#### 방문 기록 리스트 아이템

```dart
Card(
  child: ListTile(
    leading: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Icon(
        Icons.ramen_dining,  // 🍜 대신
        color: AppColors.primary,
      ),
    ),
    title: Text('맛있는국수'),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('한식'),
            Text(' · '),
            Icon(Icons.location_on, size: 12),  // 📍 대신
            Text('250m'),
          ],
        ),
        Row(
          children: [
            Icon(Icons.group, size: 14),  // 👥 대신
            SizedBox(width: 4),
            Text('5번째 방문'),
          ],
        ),
      ],
    ),
    trailing: Text('오늘'),
  ),
)
```

### 📝 Helper 함수 예시

```dart
Widget _buildStatItem({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing2),
    child: Row(
      children: [
        Icon(icon, size: 24),
        SizedBox(width: AppSpacing.spacing2),
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );
}

Widget _buildRankItem({
  required int rank,
  required String category,
  required IconData icon,
  required int count,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing1),
    child: Row(
      children: [
        Text(
          '$rank위',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(width: AppSpacing.spacing2),
        Icon(icon, size: 20),
        SizedBox(width: AppSpacing.spacing1),
        Text(category),
        Spacer(),
        Text('$count회'),
      ],
    ),
  );
}
```

### 🔍 검증 체크리스트

Phase 6 구현 완료 전 반드시 확인:

- [ ] 모든 Emoji를 Material Icons로 교체
- [ ] 슬롯머신 애니메이션에 Material Icons 사용
- [ ] 통계 카드에 Material Icons 사용
- [ ] AppColors 클래스의 색상 사용
- [ ] AppDimensions의 Border Radius 사용
- [ ] AppSpacing의 Spacing 사용
- [ ] 하드코딩된 색상 값 없음
- [ ] 일관된 카드 스타일 적용
- [ ] 친근한 메시지 톤 유지

### 📚 참고 문서

- [UI 디자인 규칙 전체 문서](../UI_DESIGN_RULES.md)
- [화면 흐름도 및 상세 설계](../SCREEN_FLOW.md)
- [Material Icons 검색](https://fonts.google.com/icons)
