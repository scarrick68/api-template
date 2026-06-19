module BlazerDashboards
  ApiObservability = {
    name: "API Observability",
    queries: [
      {
        name: "API requests by day - last 30 days",
        statement: BlazerDashboards::Queries::ApiRequestsDaily30Days.sql
      },
      {
        name: "API requests by endpoint - last 7 days",
        statement: BlazerDashboards::Queries::ApiRequestsByEndpoint7Days.sql
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
