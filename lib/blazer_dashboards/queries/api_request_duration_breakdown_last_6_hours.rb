module BlazerDashboards
  module Queries
    class ApiRequestDurationBreakdownLast6Hours
      def self.sql
        <<~SQL
          select
            date_trunc('minute', occurred_at) as minute,
            round((avg(value) filter (where name = 'observability.api.request.duration.app_compute_ms'))::numeric, 2) as app_compute_ms,
            round((avg(value) filter (where name = 'observability.api.request.duration.db_ms'))::numeric, 2) as db_ms,
            round((avg(value) filter (where name = 'observability.api.request.duration.view_ms'))::numeric, 2) as view_ms,
            round((avg(value) filter (where name = 'observability.api.request.duration_ms'))::numeric, 2) as total_ms
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
