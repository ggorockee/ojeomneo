package auth

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type TokenType string

const (
	AccessToken  TokenType = "access"
	RefreshToken TokenType = "refresh"
)

type Claims struct {
	UserID uint      `json:"user_id"`
	Type   TokenType `json:"type"`
	jwt.RegisteredClaims
}

// GenerateAccessToken generates an access token
func GenerateAccessToken(userID uint, secretKey string, expireMinutes int) (string, error) {
	claims := Claims{
		UserID: userID,
		Type:   AccessToken,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(expireMinutes) * time.Minute)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secretKey))
}

// GenerateRefreshToken generates a refresh token
func GenerateRefreshToken(userID uint, secretKey string, expireDays int) (string, error) {
	claims := Claims{
		UserID: userID,
		Type:   RefreshToken,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(expireDays) * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secretKey))
}

// ValidateAccessToken validates an access token
func ValidateAccessToken(tokenString, secretKey string) (*Claims, error) {
	return validateToken(tokenString, secretKey, AccessToken)
}

// ValidateRefreshToken validates a refresh token
func ValidateRefreshToken(tokenString, secretKey string) (*Claims, error) {
	return validateToken(tokenString, secretKey, RefreshToken)
}

func validateToken(tokenString, secretKey string, expectedType TokenType) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(secretKey), nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}

	if claims.Type != expectedType {
		return nil, errors.New("invalid token type")
	}

	return claims, nil
}

// GenerateTokenPair generates both access and refresh tokens concurrently
func GenerateTokenPair(userID uint, secretKey string, accessExpireMin, refreshExpireDays int) (accessToken, refreshToken string, err error) {
	type tokenResult struct {
		token string
		err   error
	}

	accessCh := make(chan tokenResult, 1)
	refreshCh := make(chan tokenResult, 1)

	// Generate access token in goroutine
	go func() {
		token, err := GenerateAccessToken(userID, secretKey, accessExpireMin)
		accessCh <- tokenResult{token, err}
	}()

	// Generate refresh token in goroutine
	go func() {
		token, err := GenerateRefreshToken(userID, secretKey, refreshExpireDays)
		refreshCh <- tokenResult{token, err}
	}()

	// Wait for both results
	accessResult := <-accessCh
	if accessResult.err != nil {
		return "", "", accessResult.err
	}

	refreshResult := <-refreshCh
	if refreshResult.err != nil {
		return "", "", refreshResult.err
	}

	return accessResult.token, refreshResult.token, nil
}

