module BlazerDashboards
  ApiObservability = {
    name: "API Observability",
    queries: [
      {
        name: "API requests by day - last 30 days",
        statement: <<~SQL
          select
            date_trunc('day', occurred_at) as day,
            count(*) as requests
          from metrics
          where name = 'observability.api.request'
            and occurred_at >= now() - interval '30 days'
          group by 1
          order by 1
        SQL
      },
      {
        name: "API requests by endpoint - last 7 days",
        statement: <<~SQL
          select
            properties->>'controller' as controller,
            properties->>'action' as action,
            count(*) as requests
          from metrics
          where name = 'observability.api.request'
            and occurred_at >= now() - interval '7 days'
          group by 1, 2
          order by requests desc
        SQL
      },
      {
        name: "API error rate by day - last 30 days",
        statement: <<~SQL
          select
            date_trunc('day', occurred_at) as day,
            count(*) filter (
              where (properties->>'status')::int >= 500
            ) as errors,
            count(*) as total,
            round(
              100.0 * count(*) filter (
                where (properties->>'status')::int >= 500
              ) / nullif(count(*), 0),
              2
            ) as error_rate_percent
          from metrics
          where name = 'observability.api.request'
            and occurred_at >= now() - interval '30 days'
          group by 1
          order by 1
        SQL
      },
      {
        name: "Slow API endpoints - p95 last 7 days",
        statement: <<~SQL
          select
            properties->>'controller' as controller,
            properties->>'action' as action,
            percentile_cont(0.95) within group (
              order by (properties->>'duration_ms')::numeric
            ) as p95_ms,
            count(*) as requests
          from metrics
          where name = 'observability.api.request'
            and occurred_at >= now() - interval '7 days'
            and properties ? 'duration_ms'
          group by 1, 2
          order by p95_ms desc
        SQL
      }
    ]
  }.freeze
end
