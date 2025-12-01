// Package docs Woohalabs API
//
// Documentation for Woohalabs API.
//
//	Schemes: https
//	BasePath: /woohalabs/v1
//	Version: 1.0.0
//	Host: api.woohalabs.com
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
        "contact": {},
        "version": "1.0"
    },
    "host": "api.woohalabs.com",
    "basePath": "/woohalabs/v1",
    "paths": {
        "/healthcheck": {
            "get": {
                "description": "서버 및 데이터베이스 상태 확인",
                "consumes": ["application/json"],
                "produces": ["application/json"],
                "tags": ["Health"],
                "summary": "서버 헬스체크",
                "responses": {
                    "200": {
                        "description": "OK"
                    }
                }
            }
        }
    }
}`

// SwaggerInfo holds exported Swagger Info so clients can modify it
var SwaggerInfo = &swag.Spec{
	Version:          "1.0",
	Host:             "api.woohalabs.com",
	BasePath:         "/woohalabs/v1",
	Schemes:          []string{},
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
