package seed

import (
	"log"

	"github.com/ggorockee/ojeomneo/server/internal/model"
	"gorm.io/gorm"
)

// MenuSeed 메뉴 시드 데이터
var MenuSeed = []model.Menu{
	// ========== 한식 (Korean) ==========
	{
		Name:          "된장찌개",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"위로", "평온"},
		SituationTags: model.StringArray{"혼밥", "집밥"},
		AttributeTags: model.StringArray{"따뜻한", "국물", "든든한"},
	},
	{
		Name:          "김치찌개",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"활력", "스트레스해소"},
		SituationTags: model.StringArray{"혼밥", "회식"},
		AttributeTags: model.StringArray{"따뜻한", "매운", "국물"},
	},
	{
		Name:          "삼겹살",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"보상", "활력", "행복"},
		SituationTags: model.StringArray{"회식", "데이트"},
		AttributeTags: model.StringArray{"고기", "든든한", "구이"},
	},
	{
		Name:          "불고기",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"행복", "보상"},
		SituationTags: model.StringArray{"데이트", "가족"},
		AttributeTags: model.StringArray{"고기", "달콤한", "구이"},
	},
	{
		Name:          "비빔밥",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"건강", "활력"},
		SituationTags: model.StringArray{"혼밥", "점심"},
		AttributeTags: model.StringArray{"밥", "야채", "건강한"},
	},
	{
		Name:          "칼국수",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"위로", "평온"},
		SituationTags: model.StringArray{"혼밥", "점심"},
		AttributeTags: model.StringArray{"따뜻한", "면류", "국물"},
	},
	{
		Name:          "순두부찌개",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"위로", "활력"},
		SituationTags: model.StringArray{"혼밥", "해장"},
		AttributeTags: model.StringArray{"따뜻한", "매운", "국물"},
	},
	{
		Name:          "제육볶음",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"활력", "스트레스해소"},
		SituationTags: model.StringArray{"혼밥", "점심"},
		AttributeTags: model.StringArray{"매운", "고기", "밥"},
	},
	{
		Name:          "닭볶음탕",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"활력", "보상"},
		SituationTags: model.StringArray{"회식", "가족"},
		AttributeTags: model.StringArray{"매운", "고기", "국물"},
	},
	{
		Name:          "갈비찜",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"보상", "특별한"},
		SituationTags: model.StringArray{"가족", "명절"},
		AttributeTags: model.StringArray{"고기", "달콤한", "특별한"},
	},
	{
		Name:          "해장국",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"위로", "회복"},
		SituationTags: model.StringArray{"해장", "혼밥"},
		AttributeTags: model.StringArray{"따뜻한", "국물", "든든한"},
	},
	{
		Name:          "육회",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"보상", "특별한"},
		SituationTags: model.StringArray{"회식", "데이트"},
		AttributeTags: model.StringArray{"고기", "신선한", "특별한"},
	},

	// ========== 중식 (Chinese) ==========
	{
		Name:          "짜장면",
		Category:      model.MenuCategoryChinese,
		EmotionTags:   model.StringArray{"위로", "향수"},
		SituationTags: model.StringArray{"혼밥", "배달"},
		AttributeTags: model.StringArray{"면류", "달콤한", "든든한"},
	},
	{
		Name:          "짬뽕",
		Category:      model.MenuCategoryChinese,
		EmotionTags:   model.StringArray{"활력", "스트레스해소"},
		SituationTags: model.StringArray{"혼밥", "배달"},
		AttributeTags: model.StringArray{"면류", "매운", "국물"},
	},
	{
		Name:          "탕수육",
		Category:      model.MenuCategoryChinese,
		EmotionTags:   model.StringArray{"행복", "보상"},
		SituationTags: model.StringArray{"회식", "가족"},
		AttributeTags: model.StringArray{"고기", "달콤한", "바삭한"},
	},
	{
		Name:          "마파두부",
		Category:      model.MenuCategoryChinese,
		EmotionTags:   model.StringArray{"활력", "스트레스해소"},
		SituationTags: model.StringArray{"혼밥", "점심"},
		AttributeTags: model.StringArray{"매운", "두부", "밥"},
	},
	{
		Name:          "깐풍기",
		Category:      model.MenuCategoryChinese,
		EmotionTags:   model.StringArray{"활력", "보상"},
		SituationTags: model.StringArray{"회식", "야식"},
		AttributeTags: model.StringArray{"고기", "매운", "바삭한"},
	},
	{
		Name:          "볶음밥",
		Category:      model.MenuCategoryChinese,
		EmotionTags:   model.StringArray{"편안", "향수"},
		SituationTags: model.StringArray{"혼밥", "야식"},
		AttributeTags: model.StringArray{"밥", "든든한", "간편한"},
	},

	// ========== 일식 (Japanese) ==========
	{
		Name:          "초밥",
		Category:      model.MenuCategoryJapanese,
		EmotionTags:   model.StringArray{"보상", "특별한", "행복"},
		SituationTags: model.StringArray{"데이트", "특별한날"},
		AttributeTags: model.StringArray{"해산물", "신선한", "고급"},
	},
	{
		Name:          "라멘",
		Category:      model.MenuCategoryJapanese,
		EmotionTags:   model.StringArray{"위로", "활력"},
		SituationTags: model.StringArray{"혼밥", "야식"},
		AttributeTags: model.StringArray{"면류", "국물", "따뜻한"},
	},
	{
		Name:          "돈카츠",
		Category:      model.MenuCategoryJapanese,
		EmotionTags:   model.StringArray{"보상", "행복"},
		SituationTags: model.StringArray{"혼밥", "점심"},
		AttributeTags: model.StringArray{"고기", "바삭한", "든든한"},
	},
	{
		Name:          "우동",
		Category:      model.MenuCategoryJapanese,
		EmotionTags:   model.StringArray{"위로", "평온"},
		SituationTags: model.StringArray{"혼밥", "간식"},
		AttributeTags: model.StringArray{"면류", "국물", "따뜻한"},
	},
	{
		Name:          "규동",
		Category:      model.MenuCategoryJapanese,
		EmotionTags:   model.StringArray{"편안", "든든"},
		SituationTags: model.StringArray{"혼밥", "점심"},
		AttributeTags: model.StringArray{"고기", "밥", "간편한"},
	},
	{
		Name:          "사시미",
		Category:      model.MenuCategoryJapanese,
		EmotionTags:   model.StringArray{"보상", "특별한"},
		SituationTags: model.StringArray{"데이트", "회식"},
		AttributeTags: model.StringArray{"해산물", "신선한", "고급"},
	},
	{
		Name:          "오코노미야끼",
		Category:      model.MenuCategoryJapanese,
		EmotionTags:   model.StringArray{"재미", "행복"},
		SituationTags: model.StringArray{"데이트", "친구"},
		AttributeTags: model.StringArray{"야채", "달콤한", "독특한"},
	},

	// ========== 양식 (Western) ==========
	{
		Name:          "스테이크",
		Category:      model.MenuCategoryWestern,
		EmotionTags:   model.StringArray{"보상", "특별한", "성취"},
		SituationTags: model.StringArray{"데이트", "특별한날"},
		AttributeTags: model.StringArray{"고기", "고급", "든든한"},
	},
	{
		Name:          "파스타",
		Category:      model.MenuCategoryWestern,
		EmotionTags:   model.StringArray{"행복", "로맨틱"},
		SituationTags: model.StringArray{"데이트", "점심"},
		AttributeTags: model.StringArray{"면류", "크림", "토마토"},
	},
	{
		Name:          "피자",
		Category:      model.MenuCategoryWestern,
		EmotionTags:   model.StringArray{"행복", "편안"},
		SituationTags: model.StringArray{"배달", "파티"},
		AttributeTags: model.StringArray{"치즈", "든든한", "나눔"},
	},
	{
		Name:          "햄버거",
		Category:      model.MenuCategoryWestern,
		EmotionTags:   model.StringArray{"편안", "만족"},
		SituationTags: model.StringArray{"혼밥", "간식"},
		AttributeTags: model.StringArray{"고기", "빵", "간편한"},
	},
	{
		Name:          "리조또",
		Category:      model.MenuCategoryWestern,
		EmotionTags:   model.StringArray{"위로", "로맨틱"},
		SituationTags: model.StringArray{"데이트", "점심"},
		AttributeTags: model.StringArray{"밥", "크림", "부드러운"},
	},
	{
		Name:          "샐러드",
		Category:      model.MenuCategoryWestern,
		EmotionTags:   model.StringArray{"건강", "가벼움"},
		SituationTags: model.StringArray{"다이어트", "점심"},
		AttributeTags: model.StringArray{"야채", "가벼운", "건강한"},
	},
	{
		Name:          "수프",
		Category:      model.MenuCategoryWestern,
		EmotionTags:   model.StringArray{"위로", "따뜻함"},
		SituationTags: model.StringArray{"간식", "아침"},
		AttributeTags: model.StringArray{"국물", "따뜻한", "가벼운"},
	},

	// ========== 아시안 (Asian) ==========
	{
		Name:          "쌀국수",
		Category:      model.MenuCategoryAsian,
		EmotionTags:   model.StringArray{"청량", "이국적"},
		SituationTags: model.StringArray{"혼밥", "점심"},
		AttributeTags: model.StringArray{"면류", "국물", "가벼운"},
	},
	{
		Name:          "팟타이",
		Category:      model.MenuCategoryAsian,
		EmotionTags:   model.StringArray{"활력", "이국적"},
		SituationTags: model.StringArray{"혼밥", "데이트"},
		AttributeTags: model.StringArray{"면류", "달콤한", "새콤한"},
	},
	{
		Name:          "똠양꿍",
		Category:      model.MenuCategoryAsian,
		EmotionTags:   model.StringArray{"활력", "스트레스해소"},
		SituationTags: model.StringArray{"회식", "점심"},
		AttributeTags: model.StringArray{"국물", "매운", "새콤한"},
	},
	{
		Name:          "카레",
		Category:      model.MenuCategoryAsian,
		EmotionTags:   model.StringArray{"위로", "향수"},
		SituationTags: model.StringArray{"혼밥", "점심"},
		AttributeTags: model.StringArray{"밥", "매운", "든든한"},
	},
	{
		Name:          "분짜",
		Category:      model.MenuCategoryAsian,
		EmotionTags:   model.StringArray{"청량", "건강"},
		SituationTags: model.StringArray{"점심", "데이트"},
		AttributeTags: model.StringArray{"면류", "고기", "신선한"},
	},
	{
		Name:          "반미",
		Category:      model.MenuCategoryAsian,
		EmotionTags:   model.StringArray{"활력", "이국적"},
		SituationTags: model.StringArray{"간식", "점심"},
		AttributeTags: model.StringArray{"빵", "고기", "신선한"},
	},

	// ========== 분식 (Snack) ==========
	{
		Name:          "떡볶이",
		Category:      model.MenuCategorySnack,
		EmotionTags:   model.StringArray{"활력", "스트레스해소", "향수"},
		SituationTags: model.StringArray{"간식", "야식"},
		AttributeTags: model.StringArray{"매운", "떡", "달콤한"},
	},
	{
		Name:          "김밥",
		Category:      model.MenuCategorySnack,
		EmotionTags:   model.StringArray{"편안", "향수"},
		SituationTags: model.StringArray{"간식", "소풍"},
		AttributeTags: model.StringArray{"밥", "간편한", "가벼운"},
	},
	{
		Name:          "라면",
		Category:      model.MenuCategorySnack,
		EmotionTags:   model.StringArray{"위로", "향수"},
		SituationTags: model.StringArray{"야식", "혼밥"},
		AttributeTags: model.StringArray{"면류", "매운", "국물"},
	},
	{
		Name:          "순대",
		Category:      model.MenuCategorySnack,
		EmotionTags:   model.StringArray{"향수", "편안"},
		SituationTags: model.StringArray{"간식", "야식"},
		AttributeTags: model.StringArray{"고기", "독특한", "든든한"},
	},
	{
		Name:          "튀김",
		Category:      model.MenuCategorySnack,
		EmotionTags:   model.StringArray{"행복", "편안"},
		SituationTags: model.StringArray{"간식", "야식"},
		AttributeTags: model.StringArray{"바삭한", "간편한", "다양한"},
	},
	{
		Name:          "냉면",
		Category:      model.MenuCategorySnack,
		EmotionTags:   model.StringArray{"청량", "시원함"},
		SituationTags: model.StringArray{"여름", "점심"},
		AttributeTags: model.StringArray{"면류", "시원한", "새콤한"},
	},
	{
		Name:          "만두",
		Category:      model.MenuCategorySnack,
		EmotionTags:   model.StringArray{"위로", "편안"},
		SituationTags: model.StringArray{"간식", "야식"},
		AttributeTags: model.StringArray{"고기", "따뜻한", "간편한"},
	},

	// ========== 카페/디저트 (Cafe) ==========
	{
		Name:          "케이크",
		Category:      model.MenuCategoryCafe,
		EmotionTags:   model.StringArray{"보상", "행복", "특별한"},
		SituationTags: model.StringArray{"디저트", "생일"},
		AttributeTags: model.StringArray{"달콤한", "부드러운", "특별한"},
	},
	{
		Name:          "아이스크림",
		Category:      model.MenuCategoryCafe,
		EmotionTags:   model.StringArray{"행복", "청량"},
		SituationTags: model.StringArray{"디저트", "여름"},
		AttributeTags: model.StringArray{"달콤한", "시원한", "부드러운"},
	},
	{
		Name:          "커피",
		Category:      model.MenuCategoryCafe,
		EmotionTags:   model.StringArray{"각성", "휴식"},
		SituationTags: model.StringArray{"아침", "휴식"},
		AttributeTags: model.StringArray{"카페인", "향긋한", "쓴"},
	},
	{
		Name:          "빙수",
		Category:      model.MenuCategoryCafe,
		EmotionTags:   model.StringArray{"청량", "행복"},
		SituationTags: model.StringArray{"여름", "디저트"},
		AttributeTags: model.StringArray{"시원한", "달콤한", "얼음"},
	},
	{
		Name:          "마카롱",
		Category:      model.MenuCategoryCafe,
		EmotionTags:   model.StringArray{"보상", "귀여움"},
		SituationTags: model.StringArray{"디저트", "선물"},
		AttributeTags: model.StringArray{"달콤한", "바삭한", "예쁜"},
	},
	{
		Name:          "와플",
		Category:      model.MenuCategoryCafe,
		EmotionTags:   model.StringArray{"행복", "달콤"},
		SituationTags: model.StringArray{"브런치", "디저트"},
		AttributeTags: model.StringArray{"달콤한", "바삭한", "부드러운"},
	},

	// ========== 기타 (Other) ==========
	{
		Name:          "치킨",
		Category:      model.MenuCategoryOther,
		EmotionTags:   model.StringArray{"행복", "보상", "활력"},
		SituationTags: model.StringArray{"야식", "배달", "파티"},
		AttributeTags: model.StringArray{"고기", "바삭한", "든든한"},
	},
	{
		Name:          "족발",
		Category:      model.MenuCategoryOther,
		EmotionTags:   model.StringArray{"보상", "활력"},
		SituationTags: model.StringArray{"야식", "회식"},
		AttributeTags: model.StringArray{"고기", "쫄깃한", "든든한"},
	},
	{
		Name:          "보쌈",
		Category:      model.MenuCategoryOther,
		EmotionTags:   model.StringArray{"보상", "건강"},
		SituationTags: model.StringArray{"회식", "가족"},
		AttributeTags: model.StringArray{"고기", "건강한", "든든한"},
	},
	{
		Name:          "곱창",
		Category:      model.MenuCategoryOther,
		EmotionTags:   model.StringArray{"활력", "스트레스해소"},
		SituationTags: model.StringArray{"회식", "야식"},
		AttributeTags: model.StringArray{"고기", "매운", "구이"},
	},
	{
		Name:          "양꼬치",
		Category:      model.MenuCategoryOther,
		EmotionTags:   model.StringArray{"이국적", "활력"},
		SituationTags: model.StringArray{"회식", "야식"},
		AttributeTags: model.StringArray{"고기", "향신료", "구이"},
	},
}

// SeedMenus 메뉴 시드 데이터 삽입
func SeedMenus(db *gorm.DB) error {
	for _, menu := range MenuSeed {
		// 이미 존재하는지 확인
		var existing model.Menu
		result := db.Where("name = ?", menu.Name).First(&existing)

		if result.Error == gorm.ErrRecordNotFound {
			// 새로 생성
			menu.IsActive = true
			if err := db.Create(&menu).Error; err != nil {
				log.Printf("Failed to seed menu %s: %v", menu.Name, err)
				return err
			}
			log.Printf("Seeded menu: %s", menu.Name)
		}
	}

	log.Printf("Menu seeding completed. Total: %d menus", len(MenuSeed))
	return nil
}
