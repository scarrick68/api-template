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
- Do not optimize for hypothetical misuse. Optimize for the current workflow and its established preconditions.
- Do not always use dependency injection by default. use it when it makes sense, but testing and mocking are not the only reasons to use dependency injection. Those uses can be solved with other techniques like stubbing, mocking, and fixtures.
- Establish invariants at system boundaries. Inside the engine, assume canonical data and trusted inputs rather than repeatedly validating or normalizing them,
- Do not introduce abstraction, configuration layers, or fallback behavior until there is a concrete caller or use case requiring them. Prefer the simplest implementation that satisfies current requirements.
- Use symbol keys for in-memory domain hashes. Normalize JSON or database payloads to symbol keys once when they enter application logic, and let serialization handle conversion when persisted.
- Prefer built-in Rails and Ruby functionality before writing custom implementations. Do not reimplement framework features that already exist and are well supported.
- Prefer mature, actively maintained, widely adopted gems over custom implementations when they solve a problem well and are compatible with Rails 8+. Avoid niche, abandoned, or lightly maintained dependencies.
- Follow standard Rails conventions first. Use framework abstractions where they fit naturally, introducing service objects only for reusable business logic, orchestration, or complex workflows.
- Keep mountable engines self-contained. Engine-specific models, controllers, routes, services, views, assets, migrations, and configuration belong inside the engine; host applications should primarily provide authentication, authorization, configuration, and integration.
- Keep migrations focused on a single cohesive schema change. Name migrations after the change they perform, and avoid combining unrelated features or data migrations with structural changes.
- Keep FactoryBot definitions organized with one factory per file named after the model, following standard Rails project structure.
- Prefer simple, idiomatic Rails solutions over defensive abstractions. Avoid introducing generic frameworks, indirection, or extensibility until there is a demonstrated requirement.

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
- Prefer FactoryBot factories when testing existing model instances and idempotent behavior
- Prefer inlining test data setup over helper methods. Seeing the data setup in the test itself is more readable and easier to understand than having to jump to a helper method to see what data is being created.
- Run tests with `bin/rails test` in local development env for individual files or directories. Use `bin/ci` to run all tests in CI.
- One data factory per file

Run targeted tests with:

```sh
bin/rails test path/to/test_file.rb
```

Before completing substantial changes:

```sh
bin/ci
```

## General

- Keep descriptions of the work you have done brief and to the point. Overload of descriptive text adds too much noise to read and review.
- Include a brief summary of the work you have just completed, which file or files to start reviewing through the diff (an app code entrypoint is preferred), and any upcoming next steps or follow-up work that will be done in the chunk of work.
- Name migrations for the schema change they perform, keep each migration focused on one cohesive domain change, and group related tables, indexes, foreign keys, and constraints together. Avoid mixing unrelated features or application data backfills with structural changes unless deployment safety requires separate staged migrations.
