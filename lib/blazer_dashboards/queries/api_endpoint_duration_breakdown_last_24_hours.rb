module BlazerDashboards
  module Queries
    class ApiEndpointDurationBreakdownLast24Hours
      def self.sql
        <<~SQL
          select
            labels->>'controller' as controller,
            labels->>'action' as action,
            avg(value) filter (where name = 'observability.api.request.duration.app_compute_ms') as app_compute_ms,
            avg(value) filter (where name = 'observability.api.request.duration.db_ms') as db_ms,
            avg(value) filter (where name = 'observability.api.request.duration.view_ms') as view_ms,
            avg(value) filter (where name = 'observability.api.request.duration_ms') as total_ms
          from metrics
          where occurred_at >= now() - interval '24 hours'
            and name in (
              'observability.api.request.duration_ms',
              'observability.api.request.duration.app_compute_ms',
              'observability.api.request.duration.db_ms',
              'observability.api.request.duration.view_ms'
            )
          group by controller, action
          order by total_ms desc nulls last
        SQL
      end
    end
  end
end
