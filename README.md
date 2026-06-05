# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## CORS

This template enables CORS with `rack-cors`.

- Set `CORS_ALLOWED_ORIGINS` to a comma-separated list of allowed origins.
- Cors are set in env specific config/environments/*.rb files

## API Error Handling

This template uses a common gem-style JSON error envelope.

```json
{
	"success": false,
	"errors": [
		"param is missing or the value is empty: widget"
	],
	"error_type": "bad_request",
	"request_id": "9a9de824-fdb2-4f57-9525-c3fd2930a34d"
}
```

The `request_id` value matches Rails request logging and can be used for tracing.

When details are provided (for example validation failures), they are appended to the `errors` array.

Default exception mapping:

- `ActionController::ParameterMissing` -> `400 bad_request`
- `ActionController::BadRequest` -> `400 bad_request`
- `ActiveRecord::RecordNotFound` -> `404 not_found`
- `ActiveRecord::RecordInvalid` -> `422 unprocessable_entity` (includes validation messages in `errors`)
- `ActiveRecord::RecordNotSaved` -> `422 unprocessable_entity`
- `StandardError` -> `500 internal_server_error`

This format is aligned with authentication error responses from `devise_token_auth`.
