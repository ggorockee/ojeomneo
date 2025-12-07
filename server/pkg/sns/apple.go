package sns

import (
	"context"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"math/big"
	"net/http"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// AppleUserInfo represents Apple user information
type AppleUserInfo struct {
	ID           string `json:"id"`
	Email        string `json:"email"`
	Name         string `json:"name"`
	ProfileImage string `json:"profile_image"`
}

// AppleJWKS represents Apple's JWKS response
type AppleJWKS struct {
	Keys []AppleJWK `json:"keys"`
}

// AppleJWK represents a single JWK
type AppleJWK struct {
	Kty string `json:"kty"`
	Kid string `json:"kid"`
	Use string `json:"use"`
	Alg string `json:"alg"`
	N   string `json:"n"`
	E   string `json:"e"`
}

// AppleClaims represents Apple JWT claims
type AppleClaims struct {
	jwt.RegisteredClaims
	Email         string `json:"email"`
	EmailVerified any    `json:"email_verified"` // can be bool or string
}

var (
	applePublicKeys     map[string]*rsa.PublicKey
	applePublicKeysMu   sync.RWMutex
	applePublicKeysTime time.Time
)

// getApplePublicKeys fetches and caches Apple's public keys
// Uses goroutine for concurrent fetching when cache is expired
func getApplePublicKeys(ctx context.Context) (map[string]*rsa.PublicKey, error) {
	applePublicKeysMu.RLock()
	if applePublicKeys != nil && time.Since(applePublicKeysTime) < time.Hour {
		defer applePublicKeysMu.RUnlock()
		return applePublicKeys, nil
	}
	applePublicKeysMu.RUnlock()

	// Fetch keys in goroutine for non-blocking operation
	type keysResult struct {
		keys map[string]*rsa.PublicKey
		err  error
	}
	resultCh := make(chan keysResult, 1)

	go func() {
		applePublicKeysMu.Lock()
		defer applePublicKeysMu.Unlock()

		// Double check after acquiring write lock
		if applePublicKeys != nil && time.Since(applePublicKeysTime) < time.Hour {
			resultCh <- keysResult{applePublicKeys, nil}
			return
		}

		client := &http.Client{Timeout: 10 * time.Second}
		req, err := http.NewRequestWithContext(ctx, "GET", "https://appleid.apple.com/auth/keys", nil)
		if err != nil {
			resultCh <- keysResult{nil, fmt.Errorf("failed to create request: %w", err)}
			return
		}

		resp, err := client.Do(req)
		if err != nil {
			resultCh <- keysResult{nil, fmt.Errorf("failed to fetch apple keys: %w", err)}
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			resultCh <- keysResult{nil, fmt.Errorf("apple keys API returned status %d", resp.StatusCode)}
			return
		}

		var jwks AppleJWKS
		if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
			resultCh <- keysResult{nil, fmt.Errorf("failed to decode JWKS: %w", err)}
			return
		}

		keys := make(map[string]*rsa.PublicKey)
		
		// Process keys concurrently
		var wg sync.WaitGroup
		keysMu := sync.Mutex{}
		
		for _, jwk := range jwks.Keys {
			if jwk.Kty != "RSA" {
				continue
			}

			wg.Add(1)
			go func(jwk AppleJWK) {
				defer wg.Done()

				// Decode N and E
				nBytes, err := base64.RawURLEncoding.DecodeString(jwk.N)
				if err != nil {
					return
				}
				eBytes, err := base64.RawURLEncoding.DecodeString(jwk.E)
				if err != nil {
					return
				}

				n := new(big.Int).SetBytes(nBytes)
				e := int(new(big.Int).SetBytes(eBytes).Int64())

				keysMu.Lock()
				keys[jwk.Kid] = &rsa.PublicKey{
					N: n,
					E: e,
				}
				keysMu.Unlock()
			}(jwk)
		}

		wg.Wait()

		applePublicKeys = keys
		applePublicKeysTime = time.Now()

		resultCh <- keysResult{keys, nil}
	}()

	result := <-resultCh
	return result.keys, result.err
}

// VerifyAppleToken verifies Apple identity token and returns user info
func VerifyAppleToken(ctx context.Context, identityToken string, clientID string) (*AppleUserInfo, error) {
	// Parse token header in goroutine for concurrent processing
	type parseResult struct {
		kid string
		err error
	}
	parseCh := make(chan parseResult, 1)

	go func() {
		token, _, err := jwt.NewParser().ParseUnverified(identityToken, &AppleClaims{})
		if err != nil {
			parseCh <- parseResult{"", fmt.Errorf("failed to parse token: %w", err)}
			return
		}

		kid, ok := token.Header["kid"].(string)
		if !ok || kid == "" {
			parseCh <- parseResult{"", fmt.Errorf("missing kid in token header")}
			return
		}

		parseCh <- parseResult{kid, nil}
	}()

	result := <-parseCh
	if result.err != nil {
		return nil, result.err
	}

	kid := result.kid

	// Get Apple public keys (cached, non-blocking)
	keys, err := getApplePublicKeys(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get apple public keys: %w", err)
	}

	publicKey, ok := keys[kid]
	if !ok {
		return nil, fmt.Errorf("public key not found for kid: %s", kid)
	}

	// Parse and verify token in goroutine
	type verifyResult struct {
		claims *AppleClaims
		err    error
	}
	verifyCh := make(chan verifyResult, 1)

	go func() {
		claims := &AppleClaims{}
		parserOptions := []jwt.ParserOption{
			jwt.WithValidMethods([]string{"RS256"}),
			jwt.WithExpirationRequired(),
		}

		if clientID != "" {
			parserOptions = append(parserOptions, jwt.WithAudience(clientID))
		}

		token, err := jwt.ParseWithClaims(identityToken, claims, func(token *jwt.Token) (interface{}, error) {
			return publicKey, nil
		}, parserOptions...)

		if err != nil {
			verifyCh <- verifyResult{nil, fmt.Errorf("failed to verify token: %w", err)}
			return
		}

		if !token.Valid {
			verifyCh <- verifyResult{nil, fmt.Errorf("invalid token")}
			return
		}

		if claims.Subject == "" {
			verifyCh <- verifyResult{nil, fmt.Errorf("missing sub claim")}
			return
		}

		verifyCh <- verifyResult{claims, nil}
	}()

	verifyRes := <-verifyCh
	if verifyRes.err != nil {
		return nil, verifyRes.err
	}

	claims := verifyRes.claims

	return &AppleUserInfo{
		ID:           claims.Subject,
		Email:        claims.Email,
		Name:         "", // Apple doesn't provide name in JWT
		ProfileImage: "", // Apple doesn't provide profile image
	}, nil
}

