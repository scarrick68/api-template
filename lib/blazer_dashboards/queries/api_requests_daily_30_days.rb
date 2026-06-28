module BlazerDashboards
  module Queries
    class ApiRequestsDaily30Days
      def self.sql
        <<~SQL
          select
            time as day,
            sum(value) as requests
          from rollups
          where name = 'observability.api.endpoint.requests'
            and interval = 'day'
            and time >= now() - interval '30 days'
          group by day
          order by day
        SQL
      end
    end
  end
end
