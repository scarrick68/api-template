# test/tasks/blazer_dashboards_task_test.rb

require "test_helper"
require "rake"

class BlazerDashboardsTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |task| task.name == "blazer:install_dashboards" }

    Blazer::Dashboard.where(name: "API Observability").destroy_all
    Blazer::Query.where(name: dashboard_query_names).destroy_all

    Rake::Task["blazer:install_dashboards"].reenable
  end

  test "installs api observability dashboard and queries" do
    assert_difference "Blazer::Dashboard.count", 1 do
      assert_difference "Blazer::Query.count", dashboard_query_names.size do
        Rake::Task["blazer:install_dashboards"].invoke
      end
    end

    dashboard = Blazer::Dashboard.find_by!(name: "API Observability")

    assert_equal dashboard_query_names.sort, dashboard.queries.pluck(:name).sort

    current_day_query = Blazer::Query.find_by!(name: "API requests - current day")

    assert_includes current_day_query.statement, "from metrics"
    assert_includes current_day_query.statement, Metrics::ApiRequestMetricNames::API_REQUEST_COUNT
    assert_includes current_day_query.statement, "date_trunc('day', now())"

    query = Blazer::Query.find_by!(name: "API requests by day - last 30 days")

    assert_includes query.statement, "from rollups"
    assert_includes query.statement, "observability.api.endpoint.requests"
    assert_includes query.statement, "interval '30 days'"

    p95_query = Blazer::Query.find_by!(name: "Slow API endpoints - p95 last 7 days")
    assert_includes p95_query.statement, "observability.api.endpoint.duration.p95_ms"

    breakdown_query = Blazer::Query.find_by!(name: "API request duration breakdown - last 6 hours")
    assert_includes breakdown_query.statement, "observability.api.request.duration.app_compute_ms"
    assert_includes breakdown_query.statement, "observability.api.request.duration.db_ms"
    assert_includes breakdown_query.statement, "observability.api.request.duration.view_ms"
    assert_includes breakdown_query.statement, "observability.api.request.duration_ms"

    db_heavy_query = Blazer::Query.find_by!(name: "DB-heavy API endpoints - last 24 hours")
    assert_includes db_heavy_query.statement, "db_percent"
    assert_includes db_heavy_query.statement, "observability.api.request.duration.db_ms"
  end

  test "task is idempotent" do
    Rake::Task["blazer:install_dashboards"].invoke
    Rake::Task["blazer:install_dashboards"].reenable

    assert_no_difference "Blazer::Dashboard.count" do
      assert_no_difference "Blazer::Query.count" do
        Rake::Task["blazer:install_dashboards"].invoke
      end
    end
  end

  private

  def dashboard_query_names
    [
      "API requests - current day",
      "API error rate - current day",
      "API requests by day - last 30 days",
      "API requests by endpoint - last 7 days",
      "API request duration breakdown - last 6 hours",
      "API endpoint duration breakdown - last 24 hours",
      "DB-heavy API endpoints - last 24 hours",
      "API error rate by day - last 30 days",
      "Slow API endpoints - p95 last 7 days"
    ]
  end
end
