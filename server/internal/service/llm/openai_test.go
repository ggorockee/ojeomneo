package llm

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestClient_NewClient(t *testing.T) {
	t.Run("API 키 있는 클라이언트 생성", func(t *testing.T) {
		client := NewClient("test-api-key", "gpt-4o-mini")
		assert.True(t, client.IsAvailable())
		assert.Equal(t, "gpt-4o-mini", client.model)
	})

	t.Run("API 키 없는 클라이언트 생성", func(t *testing.T) {
		client := NewClient("", "gpt-4o-mini")
		assert.False(t, client.IsAvailable())
	})
}

func TestClient_IsAvailable(t *testing.T) {
	t.Run("API 키 있으면 true", func(t *testing.T) {
		client := NewClient("sk-test-key", "gpt-4o-mini")
		assert.True(t, client.IsAvailable())
	})

	t.Run("API 키 없으면 false", func(t *testing.T) {
		client := NewClient("", "gpt-4o-mini")
		assert.False(t, client.IsAvailable())
	})
}

func TestClient_MockAnalysis(t *testing.T) {
	client := NewClient("", "gpt-4o-mini")
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
	client := NewClient("", "gpt-4o-mini")
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
