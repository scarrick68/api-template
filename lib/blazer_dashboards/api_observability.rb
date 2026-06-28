module BlazerDashboards
  ApiObservability = {
    name: "API Observability",
    queries: [
      {
        name: "API requests - current day",
        statement: BlazerDashboards::Queries::ApiRequestsCurrentDay.sql
      },
      {
        name: "API error rate - current day",
        statement: BlazerDashboards::Queries::ApiErrorRateCurrentDay.sql
      },
      {
        name: "API requests by day - last 30 days",
        statement: BlazerDashboards::Queries::ApiRequestsDaily30Days.sql
      },
      {
        name: "API requests by endpoint - last 7 days",
        statement: BlazerDashboards::Queries::ApiRequestsByEndpoint7Days.sql
      },
      {
        name: "API request duration breakdown - last 6 hours",
        statement: BlazerDashboards::Queries::ApiRequestDurationBreakdownLast6Hours.sql
      },
      {
        name: "API endpoint duration breakdown - last 24 hours",
        statement: BlazerDashboards::Queries::ApiEndpointDurationBreakdownLast24Hours.sql
      },
      {
        name: "DB-heavy API endpoints - last 24 hours",
        statement: BlazerDashboards::Queries::ApiDbHeavyEndpointsLast24Hours.sql
      },
      {
        name: "API error rate by day - last 30 days",
        statement: BlazerDashboards::Queries::ApiErrorRateDaily30Days.sql
      },
      {
        name: "Slow API endpoints - p95 last 7 days",
        statement: BlazerDashboards::Queries::ApiSlowEndpointsP95Last7Days.sql
      }
    ]
  }.freeze
end
