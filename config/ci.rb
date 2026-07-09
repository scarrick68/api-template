# Run using bin/ci
require_relative "../system/support/local_ci/services"

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  # Wait for required services to be ready before running tests. OpenSearch has sometimes been slow to start up and will cause CI failures if not ready.
  step "Services: Postgres", "ruby", "-r./system/support/local_ci/services", "-e", "LocalCi::Services.wait_for_postgres!"
  step "Services: OpenSearch", "ruby", "-r./system/support/local_ci/services", "-e", "LocalCi::Services.wait_for_opensearch!"

  step "Tests: Factory Lint", "env RAILS_ENV=test bin/rails runner 'FactoryBot.lint(traits: true)'"
  step "Tests: Validate Openapi YAML", "bin/rails yaml:lint[docs/openapi.yml]"
  step "Tests: Rails", "COVERAGE=true bin/rails test"
  step "Tests: RubyCritic", "bin/quality --no-browser || true"

  # Optional, but I plan to use FactoryBot, not seeds, for now.
  # step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Optional: Run system tests
  # step "Tests: System", "bin/rails test:system"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
