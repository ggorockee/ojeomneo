package llm

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestClient_NewClient(t *testing.T) {
	t.Run("API 키 있는 클라이언트 생성", func(t *testing.T) {
		client := NewClient("test-api-key", "gemini-1.5-flash")
		assert.True(t, client.IsAvailable())
		assert.Equal(t, "gemini-1.5-flash", client.model)
	})

	t.Run("API 키 없는 클라이언트 생성", func(t *testing.T) {
		client := NewClient("", "gemini-1.5-flash")
		assert.False(t, client.IsAvailable())
	})
}

func TestClient_IsAvailable(t *testing.T) {
	t.Run("API 키 있으면 true", func(t *testing.T) {
		client := NewClient("AIzaSy-test-key", "gemini-1.5-flash")
		assert.True(t, client.IsAvailable())
	})

	t.Run("API 키 없으면 false", func(t *testing.T) {
		client := NewClient("", "gemini-1.5-flash")
		assert.False(t, client.IsAvailable())
	})
}

func TestClient_MockAnalysis(t *testing.T) {
	client := NewClient("", "gemini-1.5-flash")
	ctx := context.Background()

	t.Run("입력 텍스트 없는 경우 기본 응답", func(t *testing.T) {
		result, err := client.AnalyzeSketch(ctx, []byte{}, "")
		require.NoError(t, err)
		assert.Equal(t, "피곤하고 위로받고 싶은", result.Emotion)
		assert.Contains(t, result.Keywords, "따뜻함")
		assert.Contains(t, result.Keywords, "포근함")
		assert.Contains(t, result.Keywords, "집밥")
		assert.Equal(t, "calm", result.Mood)
	})

	t.Run("입력 텍스트 있는 경우", func(t *testing.T) {
		result, err := client.AnalyzeSketch(ctx, []byte{}, "오늘 기분이 좋아요")
		require.NoError(t, err)
		assert.Equal(t, "뭔가 특별한 것을 원하는", result.Emotion)
		assert.Contains(t, result.Keywords, "기대감")
		assert.Contains(t, result.Keywords, "설렘")
		assert.Contains(t, result.Keywords, "새로움")
		assert.Equal(t, "bright", result.Mood)
	})
}

func TestClient_MockReason(t *testing.T) {
	client := NewClient("", "gemini-1.5-flash")
	ctx := context.Background()

	t.Run("된장찌개 추천 이유", func(t *testing.T) {
		reason, err := client.GenerateRecommendationReason(ctx, "피곤한", []string{"위로"}, "된장찌개")
		require.NoError(t, err)
		assert.Contains(t, reason, "따뜻한 국물")
		assert.Contains(t, reason, "위로")
	})

	t.Run("칼국수 추천 이유", func(t *testing.T) {
		reason, err := client.GenerateRecommendationReason(ctx, "피곤한", []string{"위로"}, "칼국수")
		require.NoError(t, err)
		assert.Contains(t, reason, "면발")
	})

	t.Run("알 수 없는 메뉴는 기본 추천 이유", func(t *testing.T) {
		reason, err := client.GenerateRecommendationReason(ctx, "피곤한", []string{"위로"}, "알수없는메뉴")
		require.NoError(t, err)
		assert.Contains(t, reason, "알수없는메뉴")
		assert.Contains(t, reason, "딱 맞는 선택")
	})
}

func TestAnalysisResult_Structure(t *testing.T) {
	result := &AnalysisResult{
		Emotion:  "피곤하고 위로받고 싶은",
		Keywords: []string{"따뜻함", "포근함", "집밥"},
		Mood:     "calm",
	}

	assert.Equal(t, "피곤하고 위로받고 싶은", result.Emotion)
	assert.Len(t, result.Keywords, 3)
	assert.Equal(t, "calm", result.Mood)
}

func TestExtractJSON(t *testing.T) {
	t.Run("순수 JSON 응답", func(t *testing.T) {
		input := `{"emotion": "피곤한", "keywords": ["따뜻함", "포근함"], "mood": "calm"}`
		result := extractJSON(input)
		assert.Equal(t, input, result)
	})

	t.Run("마크다운 코드 블록 (json 명시)", func(t *testing.T) {
		input := "```json\n{\"emotion\": \"피곤한\", \"keywords\": [\"따뜻함\"], \"mood\": \"calm\"}\n```"
		expected := `{"emotion": "피곤한", "keywords": ["따뜻함"], "mood": "calm"}`
		result := extractJSON(input)
		assert.Equal(t, expected, result)
	})

	t.Run("마크다운 코드 블록 (json 미명시)", func(t *testing.T) {
		input := "```\n{\"emotion\": \"행복한\", \"keywords\": [\"기쁨\"], \"mood\": \"bright\"}\n```"
		expected := `{"emotion": "행복한", "keywords": ["기쁨"], "mood": "bright"}`
		result := extractJSON(input)
		assert.Equal(t, expected, result)
	})

	t.Run("텍스트 앞뒤에 설명이 있는 경우", func(t *testing.T) {
		input := `분석 결과입니다:
{"emotion": "슬픈", "keywords": ["위로"], "mood": "dark"}
이상입니다.`
		expected := `{"emotion": "슬픈", "keywords": ["위로"], "mood": "dark"}`
		result := extractJSON(input)
		assert.Equal(t, expected, result)
	})

	t.Run("공백이 포함된 JSON", func(t *testing.T) {
		input := `  {"emotion": "평온한", "keywords": ["휴식"], "mood": "calm"}  `
		expected := `{"emotion": "평온한", "keywords": ["휴식"], "mood": "calm"}`
		result := extractJSON(input)
		assert.Equal(t, expected, result)
	})
}
