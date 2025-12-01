// Package docs Woohalabs API
//
// Go Fiber v2 기반 REST API 서버
//
//	Schemes: https http
//	Host: api.woohalabs.com
//	BasePath: /woohalabs/v1
//	Version: 1.0.0
//
//	Consumes:
//	- application/json
//
//	Produces:
//	- application/json
//
// swagger:meta
package docs

import "github.com/swaggo/swag"

const docTemplate = `{
    "swagger": "2.0",
    "info": {
        "description": "Go Fiber v2 기반 REST API 서버",
        "title": "Woohalabs API",
        "termsOfService": "http://swagger.io/terms/",
        "contact": {
            "name": "API Support",
            "email": "support@woohalabs.com"
        },
        "license": {
            "name": "Apache 2.0",
            "url": "http://www.apache.org/licenses/LICENSE-2.0.html"
        },
        "version": "1.0.0"
    },
    "host": "api.woohalabs.com",
    "basePath": "/woohalabs/v1",
    "paths": {
        "/healthcheck": {
            "get": {
                "description": "서버 및 데이터베이스 상태 확인",
                "consumes": [
                    "application/json"
                ],
                "produces": [
                    "application/json"
                ],
                "tags": [
                    "Health"
                ],
                "summary": "서버 헬스체크",
                "responses": {
                    "200": {
                        "description": "서버 정상",
                        "schema": {
                            "$ref": "#/definitions/handler.HealthResponse"
                        }
                    },
                    "503": {
                        "description": "서버 비정상 (DB 연결 실패)",
                        "schema": {
                            "$ref": "#/definitions/handler.HealthResponse"
                        }
                    }
                }
            }
        }
    },
    "definitions": {
        "handler.DatabaseStatus": {
            "description": "데이터베이스 연결 상태",
            "type": "object",
            "properties": {
                "connected": {
                    "type": "boolean",
                    "example": true
                },
                "latency_ms": {
                    "type": "integer",
                    "example": 5
                },
                "message": {
                    "type": "string",
                    "example": "Database connection successful"
                }
            }
        },
        "handler.HealthResponse": {
            "description": "서버 헬스체크 응답",
            "type": "object",
            "properties": {
                "database": {
                    "$ref": "#/definitions/handler.DatabaseStatus"
                },
                "service": {
                    "type": "string",
                    "example": "woohalabs-api"
                },
                "status": {
                    "type": "string",
                    "example": "ok"
                },
                "version": {
                    "type": "string",
                    "example": "1.0.0"
                }
            }
        }
    },
    "schemes": [
        "https",
        "http"
    ]
}`

// SwaggerInfo holds exported Swagger Info so clients can modify it
var SwaggerInfo = &swag.Spec{
	Version:          "1.0.0",
	Host:             "api.woohalabs.com",
	BasePath:         "/woohalabs/v1",
	Schemes:          []string{"https", "http"},
	Title:            "Woohalabs API",
	Description:      "Go Fiber v2 기반 REST API 서버",
	InfoInstanceName: "swagger",
	SwaggerTemplate:  docTemplate,
	LeftDelim:        "{{",
	RightDelim:       "}}",
}

func init() {
	swag.Register(SwaggerInfo.InstanceName(), SwaggerInfo)
}
