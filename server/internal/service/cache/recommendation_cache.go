package cache

import (
	"crypto/sha256"
	"encoding/hex"
	"strings"
	"sync"
	"time"
)

// RecommendationCache 추천 이유 캐시
type RecommendationCache struct {
	mu      sync.RWMutex
	data    map[string]cacheEntry
	ttl     time.Duration
	maxSize int
}

type cacheEntry struct {
	value     string
	expiresAt time.Time
}

// NewRecommendationCache 새 캐시 생성
func NewRecommendationCache(ttl time.Duration, maxSize int) *RecommendationCache {
	cache := &RecommendationCache{
		data:    make(map[string]cacheEntry),
		ttl:     ttl,
		maxSize: maxSize,
	}

	// 백그라운드에서 만료된 항목 정리
	go cache.cleanup()

	return cache
}

// generateKey 캐시 키 생성
func (c *RecommendationCache) generateKey(emotion string, keywords []string, menuName string) string {
	// 키워드 정렬하여 일관된 키 생성
	sortedKeywords := make([]string, len(keywords))
	copy(sortedKeywords, keywords)

	keyData := emotion + "|" + strings.Join(sortedKeywords, ",") + "|" + menuName
	hash := sha256.Sum256([]byte(keyData))
	return hex.EncodeToString(hash[:16]) // 128비트 해시
}

// Get 캐시에서 값 조회
func (c *RecommendationCache) Get(emotion string, keywords []string, menuName string) (string, bool) {
	key := c.generateKey(emotion, keywords, menuName)

	c.mu.RLock()
	defer c.mu.RUnlock()

	entry, exists := c.data[key]
	if !exists {
		return "", false
	}

	// 만료 체크
	if time.Now().After(entry.expiresAt) {
		return "", false
	}

	return entry.value, true
}

// Set 캐시에 값 저장
func (c *RecommendationCache) Set(emotion string, keywords []string, menuName string, reason string) {
	key := c.generateKey(emotion, keywords, menuName)

	c.mu.Lock()
	defer c.mu.Unlock()

	// 최대 크기 초과 시 가장 오래된 항목 삭제
	if len(c.data) >= c.maxSize {
		c.evictOldest()
	}

	c.data[key] = cacheEntry{
		value:     reason,
		expiresAt: time.Now().Add(c.ttl),
	}
}

// evictOldest 가장 오래된 항목 삭제
func (c *RecommendationCache) evictOldest() {
	var oldestKey string
	var oldestTime time.Time

	for key, entry := range c.data {
		if oldestKey == "" || entry.expiresAt.Before(oldestTime) {
			oldestKey = key
			oldestTime = entry.expiresAt
		}
	}

	if oldestKey != "" {
		delete(c.data, oldestKey)
	}
}

// cleanup 백그라운드에서 만료된 항목 정리 (10분마다)
func (c *RecommendationCache) cleanup() {
	ticker := time.NewTicker(10 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		c.mu.Lock()
		now := time.Now()
		for key, entry := range c.data {
			if now.After(entry.expiresAt) {
				delete(c.data, key)
			}
		}
		c.mu.Unlock()
	}
}

// Size 현재 캐시 크기 반환
func (c *RecommendationCache) Size() int {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return len(c.data)
}

// Clear 캐시 전체 삭제
func (c *RecommendationCache) Clear() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.data = make(map[string]cacheEntry)
}
