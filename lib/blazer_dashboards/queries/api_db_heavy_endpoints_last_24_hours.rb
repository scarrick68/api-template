module BlazerDashboards
  module Queries
    class ApiDbHeavyEndpointsLast24Hours
      def self.sql
        <<~SQL
          with endpoint_avgs as (
            select
              labels->>'controller' as controller,
              labels->>'action' as action,
              avg(value) filter (where name = 'observability.api.request.duration_ms') as total_ms,
              avg(value) filter (where name = 'observability.api.request.duration.db_ms') as db_ms,
              avg(value) filter (where name = 'observability.api.request.duration.app_compute_ms') as app_compute_ms,
              avg(value) filter (where name = 'observability.api.request.duration.view_ms') as view_ms
            from metrics
            where occurred_at >= now() - interval '24 hours'
              and name in (
                'observability.api.request.duration_ms',
                'observability.api.request.duration.app_compute_ms',
                'observability.api.request.duration.db_ms',
                'observability.api.request.duration.view_ms'
              )
            group by controller, action
          )
          select
            controller,
            action,
            total_ms,
            db_ms,
            app_compute_ms,
            view_ms,
            round((100.0 * db_ms / nullif(total_ms, 0))::numeric, 2) as db_percent
          from endpoint_avgs
          where total_ms is not null and total_ms > 0
          order by db_percent desc nulls last, total_ms desc nulls last
        SQL
      end
    end
  end
end
