module BlazerDashboards
  module Queries
    class ApiErrorRateCurrentDay
      def self.sql
        <<~SQL
          with totals as (
            select
              date_trunc('hour', occurred_at) as hour,
              sum(value) as total
            from metrics
            where name = 'observability.api.request.count'
              and occurred_at >= date_trunc('day', now())
            group by hour
          ),
          errors as (
            select
              date_trunc('hour', occurred_at) as hour,
              sum(value) as errors
            from metrics
            where name = 'observability.api.request.count'
              and (labels->>'status')::int between 400 and 599
              and occurred_at >= date_trunc('day', now())
            group by hour
          )
          select
            totals.hour,
            coalesce(errors.errors, 0) as errors,
            totals.total,
            round((100.0 * coalesce(errors.errors, 0) / nullif(totals.total, 0))::numeric, 2) as error_rate_percent
          from totals
          left join errors on errors.hour = totals.hour
          order by totals.hour
        SQL
      end
    end
  end
end
