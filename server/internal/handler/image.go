package handler

import (
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/ggorockee/ojeomneo/server/internal/service/cloudflare"
)

// ImageHandler 이미지 업로드 핸들러
type ImageHandler struct {
	cfImages *cloudflare.ImagesClient
	logger   *zap.Logger
}

// NewImageHandler ImageHandler 생성자
func NewImageHandler(cfImages *cloudflare.ImagesClient, logger *zap.Logger) *ImageHandler {
	return &ImageHandler{
		cfImages: cfImages,
		logger:   logger,
	}
}

// 허용된 이미지 확장자
var allowedExtensions = map[string]bool{
	".jpg":  true,
	".jpeg": true,
	".png":  true,
	".gif":  true,
	".webp": true,
}

// 최대 파일 크기 (10MB)
const maxFileSize = 10 * 1024 * 1024

// Upload godoc
// @Summary 이미지 업로드
// @Description 이미지를 Cloudflare Images에 업로드합니다
// @Tags Image
// @Accept multipart/form-data
// @Produce json
// @Param file formData file true "이미지 파일 (jpg, jpeg, png, gif, webp)"
// @Param type formData string false "이미지 타입 (sketch, menu)"
// @Success 200 {object} map[string]interface{} "업로드 성공"
// @Failure 400 {object} map[string]interface{} "잘못된 요청"
// @Failure 500 {object} map[string]interface{} "서버 오류"
// @Router /images/upload [post]
func (h *ImageHandler) Upload(c *fiber.Ctx) error {
	start := time.Now()
	
	// Cloudflare 클라이언트 확인
	if !h.cfImages.IsAvailable() {
		h.logger.Warn("Image upload service not available")
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"success": false,
			"error":   "image upload service not available",
		})
	}

	// 파일 가져오기
	file, err := c.FormFile("file")
	if err != nil {
		h.logger.Warn("Image upload missing file",
			zap.String("ip", c.IP()),
			zap.Error(err),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "file is required",
		})
	}

	// 파일 크기 검증
	if file.Size > maxFileSize {
		h.logger.Warn("Image upload file too large",
			zap.Int64("file_size", file.Size),
			zap.Int64("max_size", maxFileSize),
			zap.String("filename", file.Filename),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   fmt.Sprintf("file size exceeds limit (%d MB)", maxFileSize/(1024*1024)),
		})
	}

	// 파일 확장자 검증
	ext := strings.ToLower(filepath.Ext(file.Filename))
	if !allowedExtensions[ext] {
		h.logger.Warn("Image upload invalid extension",
			zap.String("extension", ext),
			zap.String("filename", file.Filename),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid file type. allowed: jpg, jpeg, png, gif, webp",
		})
	}

	// 파일 읽기
	f, err := file.Open()
	if err != nil {
		h.logger.Error("Image upload failed to open file",
			zap.String("filename", file.Filename),
			zap.Error(err),
		)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   "failed to read file",
		})
	}
	defer f.Close()

	fileData := make([]byte, file.Size)
	if _, err := f.Read(fileData); err != nil {
		h.logger.Error("Image upload failed to read file data",
			zap.String("filename", file.Filename),
			zap.Error(err),
		)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   "failed to read file data",
		})
	}

	// 이미지 타입 (메타데이터용)
	imageType := c.FormValue("type", "general")

	// 고유 파일명 생성
	newFilename := fmt.Sprintf("%s_%s%s", imageType, uuid.New().String(), ext)

	// 메타데이터 설정
	metadata := map[string]string{
		"type":     imageType,
		"original": file.Filename,
	}

	// Cloudflare에 업로드
	imageInfo, err := h.cfImages.UploadFromFile(newFilename, fileData, metadata)
	duration := time.Since(start)
	
	if err != nil {
		go func() {
			h.logger.Error("Image upload failed",
				zap.Error(err),
				zap.String("filename", file.Filename),
				zap.String("image_type", imageType),
				zap.Duration("duration", duration),
			)
		}()
		
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   "failed to upload image: " + err.Error(),
		})
	}

	go func() {
		h.logger.Info("Image upload completed",
			zap.String("image_id", imageInfo.ID),
			zap.String("filename", imageInfo.Filename),
			zap.String("image_type", imageType),
			zap.Int64("file_size", file.Size),
			zap.Duration("duration", duration),
		)
	}()

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"id":            imageInfo.ID,
			"filename":      imageInfo.Filename,
			"url":           imageInfo.PublicURL,
			"thumbnail_url": h.cfImages.GetThumbnailURL(imageInfo.ID),
		},
	})
}

// UploadFromURL godoc
// @Summary URL에서 이미지 업로드
// @Description URL에서 이미지를 가져와 Cloudflare Images에 업로드합니다
// @Tags Image
// @Accept json
// @Produce json
// @Param body body UploadFromURLRequest true "업로드 요청"
// @Success 200 {object} map[string]interface{} "업로드 성공"
// @Failure 400 {object} map[string]interface{} "잘못된 요청"
// @Failure 500 {object} map[string]interface{} "서버 오류"
// @Router /images/upload-url [post]
func (h *ImageHandler) UploadFromURL(c *fiber.Ctx) error {
	// Cloudflare 클라이언트 확인
	if !h.cfImages.IsAvailable() {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"success": false,
			"error":   "image upload service not available",
		})
	}

	// 요청 파싱
	var req UploadFromURLRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid request body",
		})
	}

	if req.URL == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "url is required",
		})
	}

	// 메타데이터 설정
	metadata := map[string]string{
		"type":   req.Type,
		"source": "url",
	}

	// Cloudflare에 업로드
	imageInfo, err := h.cfImages.UploadFromURL(req.URL, metadata)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   "failed to upload image: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"id":            imageInfo.ID,
			"filename":      imageInfo.Filename,
			"url":           imageInfo.PublicURL,
			"thumbnail_url": h.cfImages.GetThumbnailURL(imageInfo.ID),
		},
	})
}

// UploadFromURLRequest URL 업로드 요청
type UploadFromURLRequest struct {
	URL  string `json:"url"`
	Type string `json:"type"`
}

// Delete godoc
// @Summary 이미지 삭제
// @Description Cloudflare Images에서 이미지를 삭제합니다
// @Tags Image
// @Accept json
// @Produce json
// @Param id path string true "이미지 ID"
// @Success 200 {object} map[string]interface{} "삭제 성공"
// @Failure 400 {object} map[string]interface{} "잘못된 요청"
// @Failure 500 {object} map[string]interface{} "서버 오류"
// @Router /images/{id} [delete]
func (h *ImageHandler) Delete(c *fiber.Ctx) error {
	// Cloudflare 클라이언트 확인
	if !h.cfImages.IsAvailable() {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"success": false,
			"error":   "image service not available",
		})
	}

	imageID := c.Params("id")
	if imageID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "image id is required",
		})
	}

	if err := h.cfImages.Delete(imageID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   "failed to delete image: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "image deleted successfully",
	})
}
