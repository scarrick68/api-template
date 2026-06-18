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

    query = Blazer::Query.find_by!(name: "API requests by day - last 30 days")

    assert_includes query.statement, "from metrics"
    assert_includes query.statement, Metrics::ApiRequestMetricNames::API_REQUEST_COUNT
    assert_includes query.statement, "interval '30 days'"

    p95_query = Blazer::Query.find_by!(name: "Slow API endpoints - p95 last 7 days")
    assert_includes p95_query.statement, Metrics::ApiRequestMetricNames::API_REQUEST_DURATION_MS
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
      "API requests by day - last 30 days",
      "API requests by endpoint - last 7 days",
      "API error rate by day - last 30 days",
      "Slow API endpoints - p95 last 7 days"
    ]
  end
end
