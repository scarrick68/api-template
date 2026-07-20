module BlazerDashboards
  module Queries
    class ApiErrorRateDaily30Days
      def self.sql
        <<~SQL
          with totals as (
            select
              time as day,
              sum(value) as total
            from rollups
            where name = 'observability.api.endpoint.requests'
              and interval = 'day'
              and time >= now() - interval '30 days'
            group by day
          ),
          client_errors as (
            select
              time as day,
              sum(value) as client_errors
            from rollups
            where name = 'observability.api.endpoint.client_errors'
              and interval = 'day'
              and time >= now() - interval '30 days'
            group by day
          ),
          server_errors as (
            select
              time as day,
              sum(value) as server_errors
            from rollups
            where name = 'observability.api.endpoint.server_errors'
              and interval = 'day'
              and time >= now() - interval '30 days'
            group by day
          )
          select
            totals.day,
            coalesce(client_errors.client_errors, 0) + coalesce(server_errors.server_errors, 0) as errors,
            totals.total,
            round(
              (
                100.0 * (coalesce(client_errors.client_errors, 0) + coalesce(server_errors.server_errors, 0))
                / nullif(totals.total, 0)
              )::numeric,
              2
            ) as error_rate_percent
          from totals
          left join client_errors on client_errors.day = totals.day
          left join server_errors on server_errors.day = totals.day
          order by totals.day
        SQL
      end
    end
  end
end
