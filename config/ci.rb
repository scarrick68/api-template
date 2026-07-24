# Run using bin/ci
require_relative "../system/support/local_ci/services"

CI.run do
  failed_steps = []

  run_step = lambda do |title, *command|
    step(title, *command)
    failed_steps << title unless results.last
  end

  run_step.call "Setup", "bin/setup --skip-server"

  run_step.call "Style: Ruby", "bin/rubocop"

  run_step.call "Security: Gem audit", "bin/bundler-audit"
  run_step.call "Security: Importmap vulnerability audit", "bin/importmap audit"
  run_step.call "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  # Wait for required services to be ready before running tests. OpenSearch has sometimes been slow to start up and will cause CI failures if not ready.
  run_step.call "Services: Postgres", "ruby", "-r./system/support/local_ci/services", "-e", "LocalCi::Services.wait_for_postgres!"
  run_step.call "Services: OpenSearch", "ruby", "-r./system/support/local_ci/services", "-e", "LocalCi::Services.wait_for_opensearch!"

  # Informational check: validate local production boot path without blocking local CI.
  run_step.call "Smoke: Prod mode launch (non-blocking)", "bundle exec rails local_ci:prod_local_smoke || true"

  run_step.call "Tests: Factory Lint", "env RAILS_ENV=test bin/rails factory_bot:lint"
  run_step.call "Tests: Validate Openapi YAML", "bin/rails yaml:lint[docs/openapi.yml]"
  run_step.call "Tests: Rails", "COVERAGE=true bin/rails test"
  run_step.call "Tests: RubyCritic", "bin/quality --no-browser || true"

  # Optional, but I plan to use FactoryBot, not seeds, for now.
  # step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Optional: Run system tests
  # step "Tests: System", "bin/rails test:system"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  if !success? && failed_steps.any?
    failure "Failed Tasks (#{failed_steps.length})", "Review the list below for failing CI steps"
    failed_steps.each_with_index do |title, index|
      echo("#{index + 1}. #{title}", type: :error)
    end
  end

  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
