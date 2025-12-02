package llm

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// Client OpenAI API 클라이언트
type Client struct {
	apiKey     string
	model      string
	httpClient *http.Client
	baseURL    string
}

// NewClient 새 OpenAI 클라이언트 생성
func NewClient(apiKey, model string) *Client {
	return &Client{
		apiKey: apiKey,
		model:  model,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		baseURL: "https://api.openai.com/v1",
	}
}

// AnalysisResult 스케치 분석 결과
type AnalysisResult struct {
	Emotion  string   `json:"emotion"`
	Keywords []string `json:"keywords"`
	Mood     string   `json:"mood"`
}

// RecommendationReason 추천 이유 생성 결과
type RecommendationReason struct {
	Reason string `json:"reason"`
}

// AnalyzeSketch 스케치 이미지를 분석하여 감정/키워드/분위기 추출
func (c *Client) AnalyzeSketch(ctx context.Context, imageData []byte, inputText string) (*AnalysisResult, error) {
	if c.apiKey == "" {
		return c.mockAnalysis(inputText), nil
	}

	base64Image := base64.StdEncoding.EncodeToString(imageData)

	systemPrompt := `당신은 감성적인 음식 추천가입니다. 사용자가 그린 그림이나 낙서를 보고
그 순간의 기분, 감정, 분위기를 따뜻하게 읽어주세요.

정확한 분석보다는 공감과 위로를 담은 해석을 해주세요.`

	userPrompt := `이 그림을 보고 다음을 분석해주세요:

1. 그림에서 느껴지는 감정 (한 문장, 예: "피곤하고 위로받고 싶은")
2. 연상되는 키워드 3개 (음식과 연관지을 수 있는 것들)
3. 분위기 (bright/calm/dark 중 하나)

반드시 아래 JSON 형식으로만 응답해주세요:
{"emotion": "...", "keywords": ["...", "...", "..."], "mood": "..."}`

	if inputText != "" {
		userPrompt = fmt.Sprintf(`사용자가 그림과 함께 다음 메시지를 남겼습니다: "%s"

%s`, inputText, userPrompt)
	}

	messages := []map[string]interface{}{
		{
			"role":    "system",
			"content": systemPrompt,
		},
		{
			"role": "user",
			"content": []map[string]interface{}{
				{
					"type": "text",
					"text": userPrompt,
				},
				{
					"type": "image_url",
					"image_url": map[string]string{
						"url":    fmt.Sprintf("data:image/png;base64,%s", base64Image),
						"detail": "low",
					},
				},
			},
		},
	}

	reqBody := map[string]interface{}{
		"model":       c.model,
		"messages":    messages,
		"max_tokens":  500,
		"temperature": 0.7,
	}

	respBody, err := c.doRequest(ctx, "/chat/completions", reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze sketch: %w", err)
	}

	content, err := c.extractContent(respBody)
	if err != nil {
		return nil, err
	}

	var result AnalysisResult
	if err := json.Unmarshal([]byte(content), &result); err != nil {
		return nil, fmt.Errorf("failed to parse analysis result: %w", err)
	}

	return &result, nil
}

// GenerateRecommendationReason 메뉴 추천 이유 생성
func (c *Client) GenerateRecommendationReason(ctx context.Context, emotion string, keywords []string, menuName string) (string, error) {
	if c.apiKey == "" {
		return c.mockReason(emotion, menuName), nil
	}

	prompt := fmt.Sprintf(`감정: %s
키워드: %v

위 상태의 사람에게 어울리는 음식으로 "%s"을 추천합니다.
왜 이 음식이 어울리는지 2문장 이내로 따뜻하고 공감가는 문체로 설명해주세요.
설명만 출력하고 다른 텍스트는 포함하지 마세요.`, emotion, keywords, menuName)

	messages := []map[string]interface{}{
		{
			"role":    "user",
			"content": prompt,
		},
	}

	reqBody := map[string]interface{}{
		"model":       c.model,
		"messages":    messages,
		"max_tokens":  200,
		"temperature": 0.8,
	}

	respBody, err := c.doRequest(ctx, "/chat/completions", reqBody)
	if err != nil {
		return "", fmt.Errorf("failed to generate reason: %w", err)
	}

	content, err := c.extractContent(respBody)
	if err != nil {
		return "", err
	}

	return content, nil
}

// doRequest HTTP 요청 실행
func (c *Client) doRequest(ctx context.Context, endpoint string, body map[string]interface{}) (map[string]interface{}, error) {
	jsonBody, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, "POST", c.baseURL+endpoint, bytes.NewBuffer(jsonBody))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.apiKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respData, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API error: %s - %s", resp.Status, string(respData))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(respData, &result); err != nil {
		return nil, err
	}

	return result, nil
}

// extractContent 응답에서 content 추출
func (c *Client) extractContent(resp map[string]interface{}) (string, error) {
	choices, ok := resp["choices"].([]interface{})
	if !ok || len(choices) == 0 {
		return "", fmt.Errorf("no choices in response")
	}

	choice := choices[0].(map[string]interface{})
	message := choice["message"].(map[string]interface{})
	content := message["content"].(string)

	return content, nil
}

// mockAnalysis API 키가 없을 때 사용하는 목업 응답
func (c *Client) mockAnalysis(inputText string) *AnalysisResult {
	// 입력 텍스트에 따라 다른 응답 반환
	if inputText != "" {
		return &AnalysisResult{
			Emotion:  "뭔가 특별한 것을 원하는",
			Keywords: []string{"기대감", "설렘", "새로움"},
			Mood:     "bright",
		}
	}

	return &AnalysisResult{
		Emotion:  "피곤하고 위로받고 싶은",
		Keywords: []string{"따뜻함", "포근함", "집밥"},
		Mood:     "calm",
	}
}

// mockReason API 키가 없을 때 사용하는 목업 추천 이유
func (c *Client) mockReason(emotion, menuName string) string {
	reasons := map[string]string{
		"된장찌개":  "지친 하루 끝에 따뜻한 국물 한 숟갈은 마음까지 녹여줄 거예요. 엄마가 끓여주신 것 같은 그 맛이 오늘 당신에게 필요한 위로예요.",
		"칼국수":   "따끈한 면발이 속을 편하게 해줄 거예요. 한 그릇 비우고 나면 마음도 한결 가벼워질 거예요.",
		"김치찌개":  "칼칼한 국물이 정신을 번쩍 들게 해줄 거예요. 밥 한 공기 뚝딱 비우고 나면 활력이 생길 거예요.",
		"삼겹살":   "고기 한 점의 행복이 오늘 하루의 피로를 날려줄 거예요. 스스로에게 주는 작은 선물이에요.",
		"냉면":    "시원한 육수가 복잡한 머리를 말끔하게 정리해줄 거예요. 청량한 한 그릇이 당신의 기분을 상쾌하게 바꿔줄 거예요.",
		"default": fmt.Sprintf("%s 한 그릇이 오늘 당신에게 딱 맞는 선택이에요. 맛있게 드시고 힘내세요!", menuName),
	}

	if reason, ok := reasons[menuName]; ok {
		return reason
	}
	return reasons["default"]
}

// IsAvailable API 키가 설정되어 있는지 확인
func (c *Client) IsAvailable() bool {
	return c.apiKey != ""
}
