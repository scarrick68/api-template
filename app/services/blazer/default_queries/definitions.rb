module Blazer
  module DefaultQueries
    module Definitions
      module_function

      def all
        [
          Definition.new(
            key: "api_requests_current_day",
            version: 1,
            name: "API requests - current day",
            dashboard_group: "API Observability",
            data_source: "main",
            sql_statement: BlazerDashboards::Queries::ApiRequestsCurrentDay.sql
          ),
          Definition.new(
            key: "api_error_rate_current_day",
            version: 1,
            name: "API error rate - current day",
            dashboard_group: "API Observability",
            data_source: "main",
            sql_statement: BlazerDashboards::Queries::ApiErrorRateCurrentDay.sql
          ),
          Definition.new(
            key: "api_requests_daily_30_days",
            version: 1,
            name: "API requests by day - last 30 days",
            dashboard_group: "API Observability",
            data_source: "main",
            sql_statement: BlazerDashboards::Queries::ApiRequestsDaily30Days.sql
          ),
          Definition.new(
            key: "api_requests_by_endpoint_7_days",
            version: 1,
            name: "API requests by endpoint - last 7 days",
            dashboard_group: "API Observability",
            data_source: "main",
            sql_statement: BlazerDashboards::Queries::ApiRequestsByEndpoint7Days.sql
          ),
          Definition.new(
            key: "api_request_duration_breakdown_last_6_hours",
            version: 1,
            name: "API request duration breakdown - last 6 hours",
            dashboard_group: "API Observability",
            data_source: "main",
            sql_statement: BlazerDashboards::Queries::ApiRequestDurationBreakdownLast6Hours.sql
          ),
          Definition.new(
            key: "api_endpoint_duration_breakdown_last_24_hours",
            version: 1,
            name: "API endpoint duration breakdown - last 24 hours",
            dashboard_group: "API Observability",
            data_source: "main",
            sql_statement: BlazerDashboards::Queries::ApiEndpointDurationBreakdownLast24Hours.sql
          ),
          Definition.new(
            key: "api_db_heavy_endpoints_last_24_hours",
            version: 1,
            name: "DB-heavy API endpoints - last 24 hours",
            dashboard_group: "API Observability",
            data_source: "main",
            sql_statement: BlazerDashboards::Queries::ApiDbHeavyEndpointsLast24Hours.sql
          ),
          Definition.new(
            key: "api_error_rate_daily_30_days",
            version: 1,
            name: "API error rate by day - last 30 days",
            dashboard_group: "API Observability",
            data_source: "main",
            sql_statement: BlazerDashboards::Queries::ApiErrorRateDaily30Days.sql
          ),
          Definition.new(
            key: "api_slow_endpoints_p95_last_7_days",
            version: 1,
            name: "Slow API endpoints - p95 last 7 days",
            dashboard_group: "API Observability",
            data_source: "main",
            sql_statement: BlazerDashboards::Queries::ApiSlowEndpointsP95Last7Days.sql
          )
        ].freeze
      end
    end
  end
end
