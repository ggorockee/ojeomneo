package sns

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

// FirebaseUserInfo represents Firebase user information
type FirebaseUserInfo struct {
	ID           string `json:"id"`
	Email        string `json:"email"`
	Name         string `json:"name"`
	ProfileImage string `json:"profile_image"`
}

var (
	firebaseApp     *firebase.App
	firebaseAuth    *auth.Client
	firebaseInitMu  sync.Mutex
	firebaseInitErr error
)

// InitFirebase initializes Firebase Admin SDK with JSON key from environment variable
// This should be called once at application startup
func InitFirebase(jsonKeyValue string) error {
	firebaseInitMu.Lock()
	defer firebaseInitMu.Unlock()

	if firebaseApp != nil {
		return nil // Already initialized
	}

	if jsonKeyValue == "" {
		return fmt.Errorf("FIREBASE_ADMIN_SDK_KEY is required")
	}

	// Parse JSON key to ensure it's valid
	var keyData map[string]interface{}
	if err := json.Unmarshal([]byte(jsonKeyValue), &keyData); err != nil {
		return fmt.Errorf("failed to parse Firebase Admin SDK key JSON: %w", err)
	}

	// Initialize Firebase app with credentials from JSON string
	opt := option.WithCredentialsJSON([]byte(jsonKeyValue))
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		firebaseInitErr = fmt.Errorf("failed to initialize Firebase app: %w", err)
		return firebaseInitErr
	}

	// Get Auth client
	authClient, err := app.Auth(context.Background())
	if err != nil {
		firebaseInitErr = fmt.Errorf("failed to get Firebase Auth client: %w", err)
		return firebaseInitErr
	}

	firebaseApp = app
	firebaseAuth = authClient
	return nil
}

// VerifyFirebaseIDToken verifies Firebase ID token and returns user info
// This function uses goroutines for concurrent token verification
func VerifyFirebaseIDToken(ctx context.Context, idToken string) (*FirebaseUserInfo, error) {
	// Ensure Firebase is initialized
	if firebaseAuth == nil {
		return nil, fmt.Errorf("firebase admin SDK not initialized, call InitFirebase first")
	}

	// Verify ID token in goroutine for non-blocking operation
	type verifyResult struct {
		token *auth.Token
		err   error
	}

	resultCh := make(chan verifyResult, 1)

	go func() {
		token, err := firebaseAuth.VerifyIDToken(ctx, idToken)
		resultCh <- verifyResult{token, err}
	}()

	result := <-resultCh
	if result.err != nil {
		return nil, fmt.Errorf("failed to verify Firebase ID token: %w", result.err)
	}

	token := result.token

	// Get user info concurrently
	type userResult struct {
		user *auth.UserRecord
		err  error
	}
	userCh := make(chan userResult, 1)

	go func() {
		user, err := firebaseAuth.GetUser(ctx, token.UID)
		userCh <- userResult{user, err}
	}()

	userRes := <-userCh
	if userRes.err != nil {
		// If GetUser fails, we can still use token claims
		// Extract email from token claims as fallback
		email, _ := token.Claims["email"].(string)
		name, _ := token.Claims["name"].(string)
		picture, _ := token.Claims["picture"].(string)

		return &FirebaseUserInfo{
			ID:           token.UID,
			Email:        email,
			Name:         name,
			ProfileImage: picture,
		}, nil
	}

	user := userRes.user

	// Extract user info
	email := user.Email
	if email == "" {
		// Fallback to token claims
		email, _ = token.Claims["email"].(string)
	}

	name := user.DisplayName
	if name == "" {
		// Fallback to token claims
		name, _ = token.Claims["name"].(string)
	}

	photoURL := user.PhotoURL
	if photoURL == "" {
		// Fallback to token claims
		photoURL, _ = token.Claims["picture"].(string)
	}

	return &FirebaseUserInfo{
		ID:           user.UID,
		Email:        email,
		Name:         name,
		ProfileImage: photoURL,
	}, nil
}

