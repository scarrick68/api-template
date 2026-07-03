# AGENTS.md

## Project

Rails 8 API for web and mobile clients.
Scaffolded with full Rails stack to support internal tooling from gems.

## Architecture

- API controllers inherit from `Api::BaseController < ActionController::API`.
- Internal routes inherit from `ApplicationController < ActionController::Base` unless they inherit from their own built-in controllers.
- Public JSON API endpoints live under `Api::V1`.
- SPA/mobile auth uses `devise_token_auth`.
- Admin tooling uses Devise session auth.
- Update docs when extending or updating major features or application architecture.
- Follow existing patterns in the codebase before introducing new abstractions.
- Prefer popular, well-maintained gems
- Prefer Rails-native patterns and conventions over introducing new abstractions.
- Prefer Rails built-in functionality like ActiveJob, ActiveSupport, and SolidQueue etc...
- Update openapi.yml when adding or changing API endpoints.

## Testing

- Use Minitest, FactoryBot, and Mocha.
- Do not introduce RSpec.
- Prefer integration tests for API behavior.
- Prefer testing real Rails behavior instead of mocking framework internals.
- Avoid stubbing Rails globals such as `Rails.cache`, `Rails.logger`, and `Rails.env` unless testing a difficult-to-reproduce failure path.
- Prefer creating real records with FactoryBot instead of mocking models.
- Prefer Rails helpers such as `travel_to` instead of stubbing time.
- Use Mocha primarily for application services, external dependencies, and failure-path testing.
- Keep tests compatible with parallel execution. Avoid shared global state.
- When adding or changing API endpoints, add or update integration tests that exercise the endpoint through a real HTTP request.
- Assert API responses against the OpenAPI contract when possible to ensure the contract is kept up to date and accurate.
- Include realistic examples in OpenAPI spec for new endpoints to ensure the contract is useful for consumers.
- Prefer using factorybot factories to create test data instead of inline creation of records in tests.

Run targeted tests with:

```sh
bin/rails test path/to/test_file.rb
```

Before completing substantial changes:

```sh
bin/ci
```

