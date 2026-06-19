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
          group by 1
          order by 1
        SQL
      end
    end
  end
end
