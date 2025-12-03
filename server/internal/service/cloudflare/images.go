package cloudflare

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"time"
)

// ImagesClient Cloudflare Images API 클라이언트
type ImagesClient struct {
	accountID   string
	accountHash string
	apiKey      string
	httpClient  *http.Client
}

// NewImagesClient 새 클라이언트 생성
func NewImagesClient(accountID, accountHash, apiKey string) *ImagesClient {
	return &ImagesClient{
		accountID:   accountID,
		accountHash: accountHash,
		apiKey:      apiKey,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// IsAvailable 클라이언트가 사용 가능한지 확인
func (c *ImagesClient) IsAvailable() bool {
	return c.accountID != "" && c.apiKey != ""
}

// UploadResponse Cloudflare Images 업로드 응답
type UploadResponse struct {
	Result struct {
		ID                string   `json:"id"`
		Filename          string   `json:"filename"`
		Uploaded          string   `json:"uploaded"`
		RequireSignedURLs bool     `json:"requireSignedURLs"`
		Variants          []string `json:"variants"`
	} `json:"result"`
	Success  bool     `json:"success"`
	Errors   []string `json:"errors"`
	Messages []string `json:"messages"`
}

// ImageInfo 업로드된 이미지 정보
type ImageInfo struct {
	ID        string `json:"id"`
	Filename  string `json:"filename"`
	PublicURL string `json:"public_url"`
}

// UploadFromFile 파일 데이터로 이미지 업로드
func (c *ImagesClient) UploadFromFile(filename string, fileData []byte, metadata map[string]string) (*ImageInfo, error) {
	if !c.IsAvailable() {
		return nil, fmt.Errorf("cloudflare images client not configured")
	}

	url := fmt.Sprintf("https://api.cloudflare.com/client/v4/accounts/%s/images/v1", c.accountID)

	// multipart form 생성
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	// 파일 추가
	part, err := writer.CreateFormFile("file", filename)
	if err != nil {
		return nil, fmt.Errorf("failed to create form file: %w", err)
	}
	if _, err := part.Write(fileData); err != nil {
		return nil, fmt.Errorf("failed to write file data: %w", err)
	}

	// 메타데이터 추가
	if len(metadata) > 0 {
		metadataJSON, err := json.Marshal(metadata)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal metadata: %w", err)
		}
		if err := writer.WriteField("metadata", string(metadataJSON)); err != nil {
			return nil, fmt.Errorf("failed to write metadata field: %w", err)
		}
	}

	// requireSignedURLs = false (퍼블릭 접근 허용)
	if err := writer.WriteField("requireSignedURLs", "false"); err != nil {
		return nil, fmt.Errorf("failed to write requireSignedURLs field: %w", err)
	}

	if err := writer.Close(); err != nil {
		return nil, fmt.Errorf("failed to close multipart writer: %w", err)
	}

	// HTTP 요청 생성
	req, err := http.NewRequest("POST", url, body)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	// 요청 실행
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to execute request: %w", err)
	}
	defer resp.Body.Close()

	// 응답 읽기
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// 응답 파싱
	var uploadResp UploadResponse
	if err := json.Unmarshal(respBody, &uploadResp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	if !uploadResp.Success {
		return nil, fmt.Errorf("upload failed: %v", uploadResp.Errors)
	}

	// public URL 찾기
	publicURL := ""
	for _, variant := range uploadResp.Result.Variants {
		if len(variant) > 0 {
			publicURL = variant
			break
		}
	}

	// account hash 기반 public URL 생성
	if publicURL == "" && c.accountHash != "" {
		publicURL = fmt.Sprintf("https://imagedelivery.net/%s/%s/public", c.accountHash, uploadResp.Result.ID)
	}

	return &ImageInfo{
		ID:        uploadResp.Result.ID,
		Filename:  uploadResp.Result.Filename,
		PublicURL: publicURL,
	}, nil
}

// UploadFromURL URL에서 이미지 가져와 업로드
func (c *ImagesClient) UploadFromURL(imageURL string, metadata map[string]string) (*ImageInfo, error) {
	if !c.IsAvailable() {
		return nil, fmt.Errorf("cloudflare images client not configured")
	}

	url := fmt.Sprintf("https://api.cloudflare.com/client/v4/accounts/%s/images/v1", c.accountID)

	// multipart form 생성
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	// URL 추가
	if err := writer.WriteField("url", imageURL); err != nil {
		return nil, fmt.Errorf("failed to write url field: %w", err)
	}

	// 메타데이터 추가
	if len(metadata) > 0 {
		metadataJSON, err := json.Marshal(metadata)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal metadata: %w", err)
		}
		if err := writer.WriteField("metadata", string(metadataJSON)); err != nil {
			return nil, fmt.Errorf("failed to write metadata field: %w", err)
		}
	}

	// requireSignedURLs = false
	if err := writer.WriteField("requireSignedURLs", "false"); err != nil {
		return nil, fmt.Errorf("failed to write requireSignedURLs field: %w", err)
	}

	if err := writer.Close(); err != nil {
		return nil, fmt.Errorf("failed to close multipart writer: %w", err)
	}

	// HTTP 요청 생성
	req, err := http.NewRequest("POST", url, body)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	// 요청 실행
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to execute request: %w", err)
	}
	defer resp.Body.Close()

	// 응답 읽기
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// 응답 파싱
	var uploadResp UploadResponse
	if err := json.Unmarshal(respBody, &uploadResp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	if !uploadResp.Success {
		return nil, fmt.Errorf("upload failed: %v", uploadResp.Errors)
	}

	// public URL 찾기
	publicURL := ""
	for _, variant := range uploadResp.Result.Variants {
		if len(variant) > 0 {
			publicURL = variant
			break
		}
	}

	if publicURL == "" && c.accountHash != "" {
		publicURL = fmt.Sprintf("https://imagedelivery.net/%s/%s/public", c.accountHash, uploadResp.Result.ID)
	}

	return &ImageInfo{
		ID:        uploadResp.Result.ID,
		Filename:  uploadResp.Result.Filename,
		PublicURL: publicURL,
	}, nil
}

// Delete 이미지 삭제
func (c *ImagesClient) Delete(imageID string) error {
	if !c.IsAvailable() {
		return fmt.Errorf("cloudflare images client not configured")
	}

	url := fmt.Sprintf("https://api.cloudflare.com/client/v4/accounts/%s/images/v1/%s", c.accountID, imageID)

	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.apiKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to execute request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("delete failed with status: %d", resp.StatusCode)
	}

	return nil
}

// GetPublicURL 이미지 ID로 퍼블릭 URL 생성
func (c *ImagesClient) GetPublicURL(imageID string) string {
	if c.accountHash == "" {
		return ""
	}
	return fmt.Sprintf("https://imagedelivery.net/%s/%s/public", c.accountHash, imageID)
}

// GetThumbnailURL 이미지 ID로 썸네일 URL 생성
func (c *ImagesClient) GetThumbnailURL(imageID string) string {
	if c.accountHash == "" {
		return ""
	}
	return fmt.Sprintf("https://imagedelivery.net/%s/%s/thumbnail", c.accountHash, imageID)
}
