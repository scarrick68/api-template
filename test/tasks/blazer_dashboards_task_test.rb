# test/tasks/blazer_dashboards_task_test.rb

require "test_helper"
require "rake"

class BlazerDashboardsTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |task| task.name == "blazer:install_dashboards" }

    Blazer::Dashboard.where(name: "API Observability").destroy_all
    Blazer::Query.where(name: dashboard_query_names + dashboard_query_names_with_versions).destroy_all

    Rake::Task["blazer:install_dashboards"].reenable
    Rake::Task["blazer:default_queries:install"].reenable if Rake::Task.task_defined?("blazer:default_queries:install")
  end

  test "installs api observability dashboard and queries" do
    assert_difference "Blazer::Dashboard.count", 1 do
      assert_difference "Blazer::Query.count", dashboard_query_names.size do
        Rake::Task["blazer:install_dashboards"].invoke
      end
    end

    dashboard = Blazer::Dashboard.find_by!(name: "API Observability")

    assert_equal dashboard_query_names_with_versions.sort, dashboard.queries.pluck(:name).sort

    current_day_query = Blazer::Query.find_by!(name: "API requests - current day v1")

    assert_includes current_day_query.statement, "from metrics"
    assert_includes current_day_query.statement, Metrics::ApiRequestMetricNames::API_REQUEST_COUNT
    assert_includes current_day_query.statement, "date_trunc('day', now())"

    query = Blazer::Query.find_by!(name: "API requests by day - last 30 days v1")

    assert_includes query.statement, "from rollups"
    assert_includes query.statement, "observability.api.endpoint.requests"
    assert_includes query.statement, "interval '30 days'"

    p95_query = Blazer::Query.find_by!(name: "Slow API endpoints - p95 last 7 days v1")
    assert_includes p95_query.statement, "observability.api.endpoint.duration.p95_ms"

    breakdown_query = Blazer::Query.find_by!(name: "API request duration breakdown - last 6 hours v1")
    assert_includes breakdown_query.statement, "observability.api.request.duration.app_compute_ms"
    assert_includes breakdown_query.statement, "observability.api.request.duration.db_ms"
    assert_includes breakdown_query.statement, "observability.api.request.duration.view_ms"
    assert_includes breakdown_query.statement, "observability.api.request.duration_ms"

    db_heavy_query = Blazer::Query.find_by!(name: "DB-heavy API endpoints - last 24 hours v1")
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

  test "uses preinstalled default queries without creating duplicates" do
    Rake::Task["blazer:default_queries:install"].invoke
    Rake::Task["blazer:install_dashboards"].reenable

    assert_no_difference "Blazer::Query.count" do
      Rake::Task["blazer:install_dashboards"].invoke
    end

    dashboard = Blazer::Dashboard.find_by!(name: "API Observability")
    assert_equal dashboard_query_names_with_versions.sort, dashboard.queries.pluck(:name).sort
  end

  test "creates separate dashboards for different dashboard groups" do
    custom_definitions = [
      Blazer::DefaultQueries::Definition.new(
        key: "api_requests_current_day",
        version: 1,
        name: "API requests - current day",
        dashboard_group: "API Observability",
        data_source: "main",
        sql_statement: "SELECT 1"
      ),
      Blazer::DefaultQueries::Definition.new(
        key: "billing_mrr",
        version: 1,
        name: "Billing MRR",
        dashboard_group: "Billing Observability",
        data_source: "main",
        sql_statement: "SELECT 2"
      )
    ]

    original_definitions = Blazer::DefaultQueries::Definitions.all
    Blazer::DefaultQueries::Definitions.stubs(:all).returns(custom_definitions)
    Blazer::Query.where(name: original_definitions.map { |definition| "#{definition.name} v#{definition.version}" }).delete_all
    Blazer::Dashboard.where(name: original_definitions.map(&:dashboard_group)).delete_all
    Rake::Task["blazer:install_dashboards"].reenable

    assert_difference "Blazer::Dashboard.count", 2 do
      assert_difference "Blazer::Query.count", 2 do
        Rake::Task["blazer:install_dashboards"].invoke
      end
    end

    api_dashboard = Blazer::Dashboard.find_by!(name: "API Observability")
    billing_dashboard = Blazer::Dashboard.find_by!(name: "Billing Observability")

    assert_equal [ "API requests - current day v1" ], api_dashboard.queries.pluck(:name)
    assert_equal [ "Billing MRR v1" ], billing_dashboard.queries.pluck(:name)
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

  def dashboard_query_names_with_versions
    dashboard_query_names.map { |name| "#{name} v1" }
  end
end
