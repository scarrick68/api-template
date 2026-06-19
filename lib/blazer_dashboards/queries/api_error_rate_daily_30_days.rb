module BlazerDashboards
  module Queries
    class ApiErrorRateDaily30Days
      def self.sql
        <<~SQL
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
      end
    end
  end
end
