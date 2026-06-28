module BlazerDashboards
  module Queries
    class ApiRequestDurationBreakdownLast6Hours
      def self.sql
        <<~SQL
          select
            date_trunc('minute', occurred_at) as minute,
            avg(value) filter (where name = 'observability.api.request.duration.app_compute_ms') as app_compute_ms,
            avg(value) filter (where name = 'observability.api.request.duration.db_ms') as db_ms,
            avg(value) filter (where name = 'observability.api.request.duration.view_ms') as view_ms,
            avg(value) filter (where name = 'observability.api.request.duration_ms') as total_ms
          from metrics
          where occurred_at >= now() - interval '6 hours'
            and name in (
              'observability.api.request.duration_ms',
              'observability.api.request.duration.app_compute_ms',
              'observability.api.request.duration.db_ms',
              'observability.api.request.duration.view_ms'
            )
          group by minute
          order by minute
        SQL
      end
    end
  end
end
