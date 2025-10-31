import 'restaurant_model.dart';

class MockRestaurants {
  static final List<RestaurantModel> restaurants = [
    // 한식
    const RestaurantModel(
      id: '1',
      name: '맛있는 김치찌개',
      category: '한식',
      distance: 150,
      latitude: 37.5665,
      longitude: 126.9780,
      rating: 4.5,
      description: '얼큰하고 맛있는 김치찌개 전문점',
    ),
    const RestaurantModel(
      id: '2',
      name: '할머니 손맛 정식',
      category: '한식',
      distance: 300,
      latitude: 37.5670,
      longitude: 126.9785,
      rating: 4.7,
      description: '집밥처럼 따뜻한 한정식',
    ),
    const RestaurantModel(
      id: '3',
      name: '육개장 한마당',
      category: '한식',
      distance: 450,
      latitude: 37.5675,
      longitude: 126.9790,
      rating: 4.3,
      description: '얼큰한 육개장이 일품',
    ),

    // 중식
    const RestaurantModel(
      id: '4',
      name: '황금 짜장면',
      category: '중식',
      distance: 200,
      latitude: 37.5668,
      longitude: 126.9782,
      rating: 4.4,
      description: '옛날 짜장면의 맛',
    ),
    const RestaurantModel(
      id: '5',
      name: '차이나타운',
      category: '중식',
      distance: 550,
      latitude: 37.5680,
      longitude: 126.9795,
      rating: 4.6,
      description: '정통 중식 요리 전문점',
    ),

    // 일식
    const RestaurantModel(
      id: '6',
      name: '스시 마스터',
      category: '일식',
      distance: 350,
      latitude: 37.5672,
      longitude: 126.9788,
      rating: 4.8,
      description: '신선한 회와 스시',
    ),
    const RestaurantModel(
      id: '7',
      name: '라멘 하우스',
      category: '일식',
      distance: 280,
      latitude: 37.5669,
      longitude: 126.9783,
      rating: 4.5,
      description: '진한 국물이 일품인 라멘',
    ),

    // 양식
    const RestaurantModel(
      id: '8',
      name: '파스타 천국',
      category: '양식',
      distance: 420,
      latitude: 37.5673,
      longitude: 126.9789,
      rating: 4.6,
      description: '수제 파스타 전문점',
    ),
    const RestaurantModel(
      id: '9',
      name: '스테이크 하우스',
      category: '양식',
      distance: 650,
      latitude: 37.5685,
      longitude: 126.9800,
      rating: 4.7,
      description: '육즙 가득한 스테이크',
    ),

    // 패스트푸드
    const RestaurantModel(
      id: '10',
      name: '버거킹',
      category: '패스트푸드',
      distance: 180,
      latitude: 37.5667,
      longitude: 126.9781,
      rating: 4.2,
      description: '불에 구운 와퍼',
    ),
    const RestaurantModel(
      id: '11',
      name: '맥도날드',
      category: '패스트푸드',
      distance: 220,
      latitude: 37.5668,
      longitude: 126.9784,
      rating: 4.1,
      description: '클래식 버거와 감자튀김',
    ),

    // 카페/디저트
    const RestaurantModel(
      id: '12',
      name: '스타벅스',
      category: '카페',
      distance: 120,
      latitude: 37.5664,
      longitude: 126.9779,
      rating: 4.4,
      description: '커피와 간단한 식사',
    ),
    const RestaurantModel(
      id: '13',
      name: '디저트 39',
      category: '디저트',
      distance: 380,
      latitude: 37.5674,
      longitude: 126.9791,
      rating: 4.5,
      description: '달콤한 디저트 전문점',
    ),

    // 분식
    const RestaurantModel(
      id: '14',
      name: '신전 떡볶이',
      category: '분식',
      distance: 250,
      latitude: 37.5669,
      longitude: 126.9785,
      rating: 4.3,
      description: '매콤달콤 떡볶이',
    ),
    const RestaurantModel(
      id: '15',
      name: '김밥천국',
      category: '분식',
      distance: 190,
      latitude: 37.5666,
      longitude: 126.9782,
      rating: 4.2,
      description: '다양한 김밥과 분식',
    ),

    // 풍무역 주변 맛집 (김포 풍무동)
    // 한식
    const RestaurantModel(
      id: '16',
      name: '풍무 손칼국수',
      category: '한식',
      distance: 120,
      latitude: 37.6151,
      longitude: 126.7156,
      rating: 4.6,
      description: '수제 칼국수와 만두가 일품',
    ),
    const RestaurantModel(
      id: '17',
      name: '풍무 삼계탕',
      category: '한식',
      distance: 280,
      latitude: 37.6155,
      longitude: 126.7160,
      rating: 4.5,
      description: '보양식 삼계탕 전문점',
    ),
    const RestaurantModel(
      id: '18',
      name: '풍무 감자탕',
      category: '한식',
      distance: 350,
      latitude: 37.6148,
      longitude: 126.7152,
      rating: 4.4,
      description: '푸짐한 감자탕과 뼈해장국',
    ),

    // 중식
    const RestaurantModel(
      id: '19',
      name: '풍무 짜장명가',
      category: '중식',
      distance: 180,
      latitude: 37.6153,
      longitude: 126.7158,
      rating: 4.5,
      description: '직접 만든 짜장면과 탕수육',
    ),
    const RestaurantModel(
      id: '20',
      name: '차이나 풍무점',
      category: '중식',
      distance: 420,
      latitude: 37.6157,
      longitude: 126.7163,
      rating: 4.6,
      description: '정통 중화요리 전문점',
    ),

    // 일식
    const RestaurantModel(
      id: '21',
      name: '풍무 초밥',
      category: '일식',
      distance: 250,
      latitude: 37.6154,
      longitude: 126.7159,
      rating: 4.7,
      description: '신선한 초밥과 사시미',
    ),
    const RestaurantModel(
      id: '22',
      name: '풍무 돈카츠',
      category: '일식',
      distance: 310,
      latitude: 37.6150,
      longitude: 126.7155,
      rating: 4.4,
      description: '바삭한 등심 돈카츠',
    ),

    // 양식
    const RestaurantModel(
      id: '23',
      name: '풍무 파스타',
      category: '양식',
      distance: 390,
      latitude: 37.6156,
      longitude: 126.7161,
      rating: 4.5,
      description: '홈메이드 파스타와 피자',
    ),
    const RestaurantModel(
      id: '24',
      name: '풍무 스테이크',
      category: '양식',
      distance: 480,
      latitude: 37.6159,
      longitude: 126.7165,
      rating: 4.6,
      description: '프리미엄 스테이크 전문점',
    ),

    // 패스트푸드
    const RestaurantModel(
      id: '25',
      name: '롯데리아 풍무역점',
      category: '패스트푸드',
      distance: 90,
      latitude: 37.6150,
      longitude: 126.7155,
      rating: 4.2,
      description: '풍무역 바로 앞 버거 전문점',
    ),
    const RestaurantModel(
      id: '26',
      name: 'KFC 풍무점',
      category: '패스트푸드',
      distance: 320,
      latitude: 37.6155,
      longitude: 126.7160,
      rating: 4.3,
      description: '바삭한 치킨과 버거',
    ),

    // 카페
    const RestaurantModel(
      id: '27',
      name: '투썸플레이스 풍무점',
      category: '카페',
      distance: 150,
      latitude: 37.6152,
      longitude: 126.7157,
      rating: 4.4,
      description: '디저트와 커피가 맛있는 카페',
    ),
    const RestaurantModel(
      id: '28',
      name: '이디야커피 풍무역점',
      category: '카페',
      distance: 110,
      latitude: 37.6151,
      longitude: 126.7156,
      rating: 4.3,
      description: '합리적인 가격의 카페',
    ),
    const RestaurantModel(
      id: '29',
      name: '풍무 베이커리카페',
      category: '카페',
      distance: 270,
      latitude: 37.6154,
      longitude: 126.7159,
      rating: 4.5,
      description: '직접 구운 빵과 커피',
    ),

    // 디저트
    const RestaurantModel(
      id: '30',
      name: '설빙 풍무점',
      category: '디저트',
      distance: 340,
      latitude: 37.6156,
      longitude: 126.7161,
      rating: 4.5,
      description: '시원한 빙수 전문점',
    ),
    const RestaurantModel(
      id: '31',
      name: '풍무 케이크하우스',
      category: '디저트',
      distance: 410,
      latitude: 37.6157,
      longitude: 126.7163,
      rating: 4.6,
      description: '수제 케이크와 마카롱',
    ),

    // 분식
    const RestaurantModel(
      id: '32',
      name: '풍무 떡볶이',
      category: '분식',
      distance: 160,
      latitude: 37.6152,
      longitude: 126.7157,
      rating: 4.3,
      description: '매콤한 떡볶이와 튀김',
    ),
    const RestaurantModel(
      id: '33',
      name: '풍무 김밥나라',
      category: '분식',
      distance: 210,
      latitude: 37.6153,
      longitude: 126.7158,
      rating: 4.2,
      description: '다양한 종류의 김밥',
    ),
  ];

  // 카테고리별로 필터링
  static List<RestaurantModel> getByCategory(String category) {
    return restaurants.where((r) => r.category == category).toList();
  }

  // 거리 범위로 필터링 (미터 단위)
  static List<RestaurantModel> getByDistance(double maxDistance) {
    return restaurants.where((r) => r.distance <= maxDistance).toList();
  }

  // 랜덤으로 1개 가져오기
  static RestaurantModel getRandom() {
    return restaurants[DateTime.now().millisecondsSinceEpoch % restaurants.length];
  }

  // ID로 찾기
  static RestaurantModel? getById(String id) {
    try {
      return restaurants.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }
}
