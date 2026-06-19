module BlazerDashboards
  module Queries
    class ApiRequestsByEndpoint7Days
      def self.sql
        <<~SQL
          select
            dimensions->>'controller' as controller,
            dimensions->>'action' as action,
            sum(value) as requests
          from rollups
          where name = 'observability.api.endpoint.requests'
            and interval = 'day'
            and time >= now() - interval '7 days'
          group by 1, 2
          order by requests desc
        SQL
      end
    end
  end
end
