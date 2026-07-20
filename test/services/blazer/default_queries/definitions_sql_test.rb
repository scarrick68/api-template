require "test_helper"

class BlazerDefaultQueriesDefinitionsSqlTest < ActiveSupport::TestCase
  setup do
    Metric.delete_all
    Rollup.delete_all
  end

  test "all default query sql statements are valid" do
    definitions = Blazer::DefaultQueries::Definitions.all

    assert definitions.any?, "expected at least one default query definition"

    definitions.each do |definition|
      sql = definition.sql_statement.to_s.strip
      assert sql.present?, "expected sql_statement to be present for #{definition.key}"

      begin
        ActiveRecord::Base.connection.execute("EXPLAIN #{sql}")
      rescue ActiveRecord::StatementInvalid => e
        flunk("invalid SQL for #{definition.key} v#{definition.version} (#{definition.name}): #{e.message}")
      end
    end
  end

  test "all default queries execute with empty metrics and rollups" do
    definitions = Blazer::DefaultQueries::Definitions.all

    assert definitions.any?, "expected at least one default query definition"

    definitions.each do |definition|
      rows = ActiveRecord::Base.connection.select_all(definition.sql_statement).to_a

      assert_kind_of Array, rows, "expected #{definition.key} to return an array"
    rescue ActiveRecord::StatementInvalid => e
      flunk("query failed on empty data for #{definition.key} v#{definition.version} (#{definition.name}): #{e.message}")
    end
  end

  test "api_requests_current_day executes with data" do
    create(
      :metric,
      :api_request_count,
      occurred_at: 1.hour.ago,
      value: 7,
      http_method: "GET",
      controller_name: "Api::V1::UsersController",
      action_name: "index",
      http_status: 200
    )

    rows = run_query("api_requests_current_day")

    assert rows.any?, "expected rows for api_requests_current_day"
    assert_equal 7, rows.sum { |row| row.fetch("requests").to_i }
  end

  test "api_error_rate_current_day computes expected percentage" do
    create(
      :metric,
      :api_request_count,
      occurred_at: 1.hour.ago,
      value: 8,
      http_method: "GET",
      controller_name: "Api::V1::UsersController",
      action_name: "index",
      http_status: 200
    )
    create(
      :metric,
      :api_request_count,
      occurred_at: 1.hour.ago,
      value: 2,
      http_method: "GET",
      controller_name: "Api::V1::UsersController",
      action_name: "index",
      http_status: 500
    )

    rows = run_query("api_error_rate_current_day")

    assert rows.any?, "expected rows for api_error_rate_current_day"

    row = rows.find { |candidate| candidate.fetch("total").to_i == 10 }
    assert row, "expected a row with total=10"
    assert_equal 2, row.fetch("errors").to_i
    assert_equal BigDecimal("20.0"), BigDecimal(row.fetch("error_rate_percent").to_s)
  end

  test "api_requests_daily_30_days executes with rollup data" do
    create(
      :rollup,
      name: "observability.api.endpoint.requests",
      interval: "day",
      time: 2.days.ago.beginning_of_day,
      dimensions: { "controller" => "Api::V1::UsersController", "action" => "index" },
      value: 13
    )

    rows = run_query("api_requests_daily_30_days")

    assert rows.any?, "expected rows for api_requests_daily_30_days"
    assert_equal 13, rows.sum { |row| row.fetch("requests").to_i }
  end

  test "api_requests_by_endpoint_7_days executes with rollup data" do
    create(
      :rollup,
      name: "observability.api.endpoint.requests",
      interval: "day",
      time: 1.day.ago.beginning_of_day,
      dimensions: { "controller" => "Api::V1::UsersController", "action" => "show" },
      value: 11
    )

    rows = run_query("api_requests_by_endpoint_7_days")

    assert rows.any?, "expected rows for api_requests_by_endpoint_7_days"
    row = rows.find { |candidate| candidate.fetch("controller") == "Api::V1::UsersController" && candidate.fetch("action") == "show" }
    assert row, "expected endpoint row for users#show"
    assert_equal 11, row.fetch("requests").to_i
  end

  test "api_request_duration_breakdown_last_6_hours executes with data" do
    occurred_at = 30.minutes.ago
    attributes = {
      occurred_at: occurred_at,
      http_method: "GET",
      controller_name: "Api::V1::UsersController",
      action_name: "show",
      http_status: 200
    }
    create(:metric, :api_request_duration, **attributes, value: 40)
    create(:metric, :api_request_app_compute_duration, **attributes, value: 15)
    create(:metric, :api_request_db_duration, **attributes, value: 20)
    create(:metric, :api_request_view_duration, **attributes, value: 5)

    rows = run_query("api_request_duration_breakdown_last_6_hours")

    assert rows.any?, "expected rows for api_request_duration_breakdown_last_6_hours"
    row = rows.find { |candidate| candidate.fetch("total_ms").to_f.positive? }
    assert row, "expected a duration row with total_ms"
    assert_in_delta 40.0, row.fetch("total_ms").to_f, 0.01
  end

  test "api_endpoint_duration_breakdown_last_24_hours executes with data" do
    attributes = {
      occurred_at: 2.hours.ago,
      http_method: "GET",
      controller_name: "Api::V1::UsersController",
      action_name: "index",
      http_status: 200
    }
    create(:metric, :api_request_duration, **attributes, value: 25)
    create(:metric, :api_request_app_compute_duration, **attributes, value: 10)
    create(:metric, :api_request_db_duration, **attributes, value: 10)
    create(:metric, :api_request_view_duration, **attributes, value: 5)

    rows = run_query("api_endpoint_duration_breakdown_last_24_hours")

    assert rows.any?, "expected rows for api_endpoint_duration_breakdown_last_24_hours"
    row = rows.find { |candidate| candidate.fetch("controller") == "Api::V1::UsersController" && candidate.fetch("action") == "index" }
    assert row, "expected endpoint breakdown row for users#index"
    assert_in_delta 25.0, row.fetch("total_ms").to_f, 0.01
  end

  test "api_db_heavy_endpoints_last_24_hours executes with data" do
    attributes = {
      occurred_at: 1.hour.ago,
      http_method: "GET",
      controller_name: "Api::V1::ReportsController",
      action_name: "index",
      http_status: 200
    }
    create(:metric, :api_request_duration, **attributes, value: 100)
    create(:metric, :api_request_app_compute_duration, **attributes, value: 20)
    create(:metric, :api_request_db_duration, **attributes, value: 70)
    create(:metric, :api_request_view_duration, **attributes, value: 10)

    rows = run_query("api_db_heavy_endpoints_last_24_hours")

    assert rows.any?, "expected rows for api_db_heavy_endpoints_last_24_hours"
    row = rows.find { |candidate| candidate.fetch("controller") == "Api::V1::ReportsController" && candidate.fetch("action") == "index" }
    assert row, "expected DB-heavy row for reports#index"
    assert_in_delta 70.0, row.fetch("db_percent").to_f, 0.01
  end

  test "api_error_rate_daily_30_days computes expected percentage" do
    day = 3.days.ago.beginning_of_day

    create(
      :rollup,
      name: "observability.api.endpoint.requests",
      interval: "day",
      time: day,
      dimensions: { "controller" => "Api::V1::UsersController", "action" => "index" },
      value: 10
    )
    create(
      :rollup,
      name: "observability.api.endpoint.client_errors",
      interval: "day",
      time: day,
      dimensions: { "controller" => "Api::V1::UsersController", "action" => "index" },
      value: 2
    )
    create(
      :rollup,
      name: "observability.api.endpoint.server_errors",
      interval: "day",
      time: day,
      dimensions: { "controller" => "Api::V1::UsersController", "action" => "index" },
      value: 1
    )

    rows = run_query("api_error_rate_daily_30_days")

    assert rows.any?, "expected rows for api_error_rate_daily_30_days"
    row = rows.find { |candidate| candidate.fetch("total").to_i == 10 }
    assert row, "expected a row with total=10"
    assert_equal 3, row.fetch("errors").to_i
    assert_equal BigDecimal("30.0"), BigDecimal(row.fetch("error_rate_percent").to_s)
  end

  test "api_slow_endpoints_p95_last_7_days executes with rollup data" do
    create(
      :rollup,
      name: "observability.api.endpoint.duration.p95_ms",
      interval: "hour",
      time: 2.hours.ago.beginning_of_hour,
      dimensions: { "controller" => "Api::V1::ReportsController", "action" => "show" },
      value: 245
    )

    rows = run_query("api_slow_endpoints_p95_last_7_days")

    assert rows.any?, "expected rows for api_slow_endpoints_p95_last_7_days"
    row = rows.find { |candidate| candidate.fetch("controller") == "Api::V1::ReportsController" && candidate.fetch("action") == "show" }
    assert row, "expected slow endpoint row for reports#show"
    assert_in_delta 245.0, row.fetch("p95_ms").to_f, 0.01
  end

  private

  def run_query(definition_key)
    definition = Blazer::DefaultQueries::Definitions.all.find { |candidate| candidate.key == definition_key }
    assert definition, "missing default query definition for #{definition_key}"

    ActiveRecord::Base.connection.select_all(definition.sql_statement).to_a
  end
end
