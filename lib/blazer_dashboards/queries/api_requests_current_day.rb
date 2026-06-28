module BlazerDashboards
  module Queries
    class ApiRequestsCurrentDay
      def self.sql
        <<~SQL
          select
            date_trunc('hour', occurred_at) as hour,
            sum(value) as requests
          from metrics
          where name = 'observability.api.request.count'
            and occurred_at >= date_trunc('day', now())
          group by hour
          order by hour
        SQL
      end
    end
  end
end
