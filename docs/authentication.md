# Authentication

This document explains the authentication model and safety defaults used in the API template.

## Surfaces and boundaries

The template uses orthogonal authentication surfaces:

- API user flows (`/auth/*`, `/api/v1/*`) use devise_token_auth token authentication. This gives us all the benefits of pw resets, token expiry, conf emails, etc...
- Admin/browser flows use Devise session authentication. At the time of writing, this is standard, simple Devise session auth and only used for admin tools and internal dashboards bc those often include Railsy MVC UIs and work much more naturally with session auth.

This separation is intentional so API token behavior and browser session behavior remain independently understandable and independently testable.

## devise_token_auth configuration posture

The template stays close to reasonable devise_token_auth defaults for compatibility, while explicitly enabling a small set of safety-focused settings:

- `change_headers_on_each_request = true`
- `max_number_of_devices = 10`
- `batch_request_buffer_throttle = 5.seconds`
- `enable_standard_devise_support = false`
- `remove_tokens_after_password_reset = true`

Notes:

- `remove_tokens_after_password_reset = true` is intentionally enabled as a defense-in-depth control so password reset can invalidate prior token state.
- The app keeps default DTA header names for compatibility with common DTA clients and helpers.

See configuration in `config/initializers/devise_token_auth.rb`.

## Why include integration tests for gem-backed behavior

Some lifecycle behavior is implemented inside devise_token_auth itself. The template still includes integration coverage because authentication is a high-risk path and we prefer an additional application-level verification layer.

The goal is not to re-test the gem internals. The goal is to verify that:

- this app's DTA configuration is wired as intended,
- token lifecycle behavior matches the security posture we expect,
- orthogonal auth surfaces do not interfere with each other as template code evolves.

Current coverage lives in `test/integration/auth_tokens_test.rb`.
