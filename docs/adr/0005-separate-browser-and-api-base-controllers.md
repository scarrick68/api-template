# ADR 0005: Separate Browser And API Base Controllers

## Status

Accepted

## Date

2026-06-21

## Key Takeaway

- API and session controllers no longer share ApplicationController as a common ancestor. Shared behavior must be extracted into explicit concerns and included where needed, rather than relying on implicit inheritance.

## Context

`ApplicationController` currently carries browser-oriented behavior such as browser capability checks and importmap cache invalidation. API controllers inheriting from `ApplicationController` implicitly inherit those browser concerns, which is not desirable for JSON token-auth APIs.

We want clear boundaries between browser/session flows and JSON API/token flows while preserving flexibility for genuinely shared request behavior.

## Decision

Adopt a split controller architecture:

1. Keep `ApplicationController < ActionController::Base` for browser/admin/HTML concerns.
2. Make `Api::BaseController < ActionController::API` for JSON API concerns.
3. Do not put potentially shared behavior directly in `ApplicationController` when it may need to apply to APIs later.
4. Extract shared behavior into explicit concerns and include them where needed.

Target concern ownership:

- `ApplicationController`: HTML/session/CSRF/importmap/browser constraints.
- `Api::BaseController`: JSON responses, token auth, API error rendering, pagination, serialization, metrics hooks.

## Rationale

- Prevents accidental coupling of API behavior to browser-only middleware/helpers.
- Makes API surface more predictable and easier to reason about.
- Reduces future refactor cost by encouraging concern-based reuse instead of inheritance leakage.
- Prevents adding things like skip_forgery_protection to `ApplicationController` to make API requests work, which could have unintended consequences for browser flows and opens up risks for security vulnerabilities if not carefully configured.

## Consequences

Positive:

- Clearer boundaries between browser and API stacks.
- Fewer side effects when adding browser-focused logic.
- More maintainable long-term architecture.

Tradeoffs:

- API controllers no longer automatically inherit behavior added to `ApplicationController`.
- Shared behavior must be intentionally extracted and included in both stacks.

## Implementation Notes

When behavior needs to span both stacks (for example request context), define a concern and include it explicitly:

```rb
module RequestContext
  extend ActiveSupport::Concern

  included do
    before_action :set_request_context
  end

  private

  def set_request_context
    Current.request_id = request.request_id
    Current.user = current_user if respond_to?(:current_user)
  end
end
```

Then include in each controller base where appropriate.

## Related Docs

- ../../README.md
- ../0002-dual-auth-boundary-for-api-and-admin.md
