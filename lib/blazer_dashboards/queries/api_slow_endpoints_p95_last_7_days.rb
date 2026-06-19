module BlazerDashboards
  module Queries
    class ApiSlowEndpointsP95Last7Days
      def self.sql
        <<~SQL
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
      end
    end
  end
end
