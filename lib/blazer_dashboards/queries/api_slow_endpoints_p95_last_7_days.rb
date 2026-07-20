module BlazerDashboards
  module Queries
    class ApiSlowEndpointsP95Last7Days
      def self.sql
        <<~SQL
          select
            dimensions->>'controller' as controller,
            dimensions->>'action' as action,
            round(max(value)::numeric, 2) as p95_ms,
            round(count(*)::numeric, 2) as samples
          from rollups
          where name = 'observability.api.endpoint.duration.p95_ms'
            and interval = 'hour'
            and time >= now() - interval '7 days'
          group by controller, action
          order by p95_ms desc
        SQL
      end
    end
  end
end
