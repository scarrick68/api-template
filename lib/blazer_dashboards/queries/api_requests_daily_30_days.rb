module BlazerDashboards
  module Queries
    class ApiRequestsDaily30Days
      def self.sql
        <<~SQL
          select
            date_trunc('day', occurred_at) as day,
            sum(value) as requests
          from metrics
          where name = 'observability.api.request.count'
            and occurred_at >= now() - interval '30 days'
          group by 1
          order by 1
        SQL
      end
    end
  end
end
