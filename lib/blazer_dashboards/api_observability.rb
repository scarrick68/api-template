module BlazerDashboards
  ApiObservability = {
    name: "API Observability",
    queries: [
      {
        name: "API requests by day - last 30 days",
        statement: <<~SQL
          select
            date_trunc('day', occurred_at) as day,
            sum(value) as requests
          from metrics
          where name = 'observability.api.request.count'
            and occurred_at >= now() - interval '30 days'
          group by 1
          order by 1
        SQL
      },
      {
        name: "API requests by endpoint - last 7 days",
        statement: <<~SQL
          select
            labels->>'controller' as controller,
            labels->>'action' as action,
            sum(value) as requests
          from metrics
          where name = 'observability.api.request.count'
            and occurred_at >= now() - interval '7 days'
          group by 1, 2
          order by requests desc
        SQL
      },
      {
        name: "API error rate by day - last 30 days",
        statement: <<~SQL
          with totals as (
            select
              date_trunc('day', occurred_at) as day,
              sum(value) as total
            from metrics
            where name = 'observability.api.request.count'
              and occurred_at >= now() - interval '30 days'
            group by 1
          ),
          errors as (
            select
              date_trunc('day', occurred_at) as day,
              sum(value) as errors
            from metrics
            where name = 'observability.api.request.error.count'
              and occurred_at >= now() - interval '30 days'
            group by 1
          )
          select
            totals.day,
            coalesce(errors.errors, 0) as errors,
            totals.total,
            round(100.0 * coalesce(errors.errors, 0) / nullif(totals.total, 0), 2) as error_rate_percent
          from totals
          left join errors on errors.day = totals.day
          order by totals.day
        SQL
      },
      {
        name: "Slow API endpoints - p95 last 7 days",
        statement: <<~SQL
          select
            labels->>'controller' as controller,
            labels->>'action' as action,
            percentile_cont(0.95) within group (
              order by value::numeric
            ) as p95_ms,
            count(*) as samples
          from metrics
          where name = 'observability.api.request.duration_ms'
            and occurred_at >= now() - interval '7 days'
          group by 1, 2
          order by p95_ms desc
        SQL
      }
    ]
  }.freeze
end
