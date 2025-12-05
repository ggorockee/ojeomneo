package service

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"

	"github.com/ggorockee/ojeomneo/server/internal/model"
	"github.com/ggorockee/ojeomneo/server/internal/service/cache"
	"github.com/ggorockee/ojeomneo/server/internal/service/llm"
)

// SketchService 스케치 서비스
type SketchService struct {
	db              *gorm.DB
	llmClient       *llm.Client
	menuService     *MenuService
	uploadPath      string
	reasonCache     *cache.RecommendationCache
}

// NewSketchService 새 스케치 서비스 생성
func NewSketchService(db *gorm.DB, llmClient *llm.Client, menuService *MenuService) *SketchService {
	uploadPath := os.Getenv("UPLOAD_PATH")
	if uploadPath == "" {
		uploadPath = "./uploads"
	}

	// 업로드 디렉토리 생성
	os.MkdirAll(filepath.Join(uploadPath, "sketches"), 0755)

	// 추천 이유 캐시 생성 (TTL: 1시간, 최대 1000개 항목)
	reasonCache := cache.NewRecommendationCache(1*time.Hour, 1000)

	return &SketchService{
		db:          db,
		llmClient:   llmClient,
		menuService: menuService,
		uploadPath:  uploadPath,
		reasonCache: reasonCache,
	}
}

// AnalyzeRequest 스케치 분석 요청
type AnalyzeRequest struct {
	ImageData []byte
	InputText string
	DeviceID  string
	UserID    *uint
}

// AnalyzeResponse 스케치 분석 응답
type AnalyzeResponse struct {
	SketchID       uuid.UUID                `json:"sketch_id"`
	Analysis       *llm.AnalysisResult      `json:"analysis"`
	Recommendation *model.RecommendationSet `json:"recommendation"`
	CreatedAt      time.Time                `json:"created_at"`
}

// Analyze 스케치 분석 및 메뉴 추천
func (s *SketchService) Analyze(ctx context.Context, req *AnalyzeRequest) (*AnalyzeResponse, error) {
	// 1. 이미지 저장
	imagePath, err := s.saveImage(req.ImageData, req.DeviceID)
	if err != nil {
		return nil, fmt.Errorf("failed to save image: %w", err)
	}

	// 2. LLM으로 스케치 분석
	analysis, err := s.llmClient.AnalyzeSketch(ctx, req.ImageData, req.InputText)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze sketch: %w", err)
	}

	// 3. 분석 결과를 JSON으로 변환
	analysisJSON, err := json.Marshal(analysis)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal analysis: %w", err)
	}

	// 4. 스케치 저장
	sketch := &model.Sketch{
		DeviceID:       req.DeviceID,
		UserID:         req.UserID,
		ImagePath:      imagePath,
		InputText:      req.InputText,
		AnalysisResult: datatypes.JSON(analysisJSON),
	}

	if err := s.db.WithContext(ctx).Create(sketch).Error; err != nil {
		return nil, fmt.Errorf("failed to save sketch: %w", err)
	}

	// 5. 키워드 기반 메뉴 검색 (Primary 1개 + Alternative 1개 = 2개만 필요)
	menus, err := s.menuService.FindByKeywords(ctx, analysis.Keywords, 2)
	if err != nil {
		return nil, fmt.Errorf("failed to find menus: %w", err)
	}

	if len(menus) == 0 {
		return nil, fmt.Errorf("no menus found")
	}

	// 6. 추천 이유 생성 및 저장
	recommendations, err := s.createRecommendations(ctx, sketch.ID, analysis, menus)
	if err != nil {
		return nil, fmt.Errorf("failed to create recommendations: %w", err)
	}

	// 7. 응답 구성
	response := &AnalyzeResponse{
		SketchID:  sketch.ID,
		Analysis:  analysis,
		CreatedAt: sketch.CreatedAt,
		Recommendation: &model.RecommendationSet{
			Primary:      s.toMenuRecommendation(&menus[0], recommendations[0].Reason),
			Alternatives: s.toAlternatives(menus[1:], recommendations[1:]),
		},
	}

	return response, nil
}

// recommendationResult goroutine 결과를 담는 구조체
type recommendationResult struct {
	index  int
	reason string
	err    error
}

// createRecommendations 추천 생성 및 저장 (goroutine 병렬 처리 + 캐싱)
func (s *SketchService) createRecommendations(ctx context.Context, sketchID uuid.UUID, analysis *llm.AnalysisResult, menus []model.Menu) ([]model.Recommendation, error) {
	recommendations := make([]model.Recommendation, len(menus))
	reasons := make([]string, len(menus))

	// 캐시 히트 여부 확인 및 goroutine 작업 분류
	var wg sync.WaitGroup
	resultChan := make(chan recommendationResult, len(menus))

	for i, menu := range menus {
		// 캐시에서 먼저 확인
		if cachedReason, found := s.reasonCache.Get(analysis.Emotion, analysis.Keywords, menu.Name); found {
			reasons[i] = cachedReason
			continue
		}

		// 캐시 미스: goroutine으로 LLM 호출
		wg.Add(1)
		go func(idx int, menuName string) {
			defer wg.Done()

			reason, err := s.llmClient.GenerateRecommendationReason(ctx, analysis.Emotion, analysis.Keywords, menuName)
			if err != nil {
				// 에러 시 기본 이유 사용
				reason = fmt.Sprintf("%s이(가) 지금 당신에게 딱 맞는 선택이에요!", menuName)
			} else {
				// 성공 시 캐시에 저장
				s.reasonCache.Set(analysis.Emotion, analysis.Keywords, menuName, reason)
			}

			resultChan <- recommendationResult{
				index:  idx,
				reason: reason,
				err:    nil,
			}
		}(i, menu.Name)
	}

	// 모든 goroutine 완료 대기 후 채널 닫기
	go func() {
		wg.Wait()
		close(resultChan)
	}()

	// 결과 수집
	for result := range resultChan {
		reasons[result.index] = result.reason
	}

	// DB 저장은 순차적으로 (데이터 무결성 보장)
	for i, menu := range menus {
		rec := model.Recommendation{
			SketchID: sketchID,
			MenuID:   menu.ID,
			Reason:   reasons[i],
			Rank:     i + 1,
		}

		if err := s.db.WithContext(ctx).Create(&rec).Error; err != nil {
			return nil, err
		}

		recommendations[i] = rec
	}

	return recommendations, nil
}

// saveImage 이미지 파일 저장
func (s *SketchService) saveImage(data []byte, deviceID string) (string, error) {
	filename := fmt.Sprintf("%s_%d.png", deviceID, time.Now().UnixNano())
	relativePath := filepath.Join("sketches", filename)
	fullPath := filepath.Join(s.uploadPath, relativePath)

	if err := os.WriteFile(fullPath, data, 0644); err != nil {
		return "", err
	}

	return relativePath, nil
}

// toMenuRecommendation Menu를 MenuRecommendation으로 변환
func (s *SketchService) toMenuRecommendation(menu *model.Menu, reason string) *model.MenuRecommendation {
	return &model.MenuRecommendation{
		MenuID:   menu.ID,
		Name:     menu.Name,
		Category: menu.Category,
		ImageURL: menu.ImageURL,
		Reason:   reason,
		Tags:     menu.GetAllTags(),
	}
}

// toAlternatives 대안 메뉴 목록 생성
func (s *SketchService) toAlternatives(menus []model.Menu, recommendations []model.Recommendation) []model.MenuRecommendation {
	if len(menus) == 0 {
		return nil
	}

	// 최대 1개의 대안만 반환 (Primary 1개 + Alternative 1개 = 총 2개)
	limit := 1
	if len(menus) < limit {
		limit = len(menus)
	}

	alternatives := make([]model.MenuRecommendation, limit)
	for i := 0; i < limit; i++ {
		alternatives[i] = model.MenuRecommendation{
			MenuID:   menus[i].ID,
			Name:     menus[i].Name,
			Category: menus[i].Category,
			ImageURL: menus[i].ImageURL,
			Reason:   recommendations[i].Reason,
			Tags:     menus[i].GetAllTags(),
		}
	}

	return alternatives
}

// GetHistory 디바이스별 히스토리 조회
func (s *SketchService) GetHistory(ctx context.Context, deviceID string, page, limit int) ([]model.Sketch, int64, error) {
	var sketches []model.Sketch
	var total int64

	query := s.db.WithContext(ctx).Model(&model.Sketch{}).
		Where("device_id = ?", deviceID)

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * limit
	if err := query.
		Preload("Recommendations").
		Preload("Recommendations.Menu").
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&sketches).Error; err != nil {
		return nil, 0, err
	}

	return sketches, total, nil
}

// GetByID ID로 스케치 조회
func (s *SketchService) GetByID(ctx context.Context, id uuid.UUID) (*model.Sketch, error) {
	var sketch model.Sketch
	if err := s.db.WithContext(ctx).
		Preload("Recommendations").
		Preload("Recommendations.Menu").
		First(&sketch, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &sketch, nil
}
