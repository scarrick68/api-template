module BlazerDashboards
  module Queries
    class ApiRequestsByEndpoint7Days
      def self.sql
        <<~SQL
          select
            dimensions->>'controller' as controller,
            dimensions->>'action' as action,
            round(sum(value)::numeric, 2) as requests
          from rollups
          where name = 'observability.api.endpoint.requests'
            and interval = 'day'
            and time >= now() - interval '7 days'
          group by controller, action
          order by requests desc
        SQL
      end
    end
  end
end
