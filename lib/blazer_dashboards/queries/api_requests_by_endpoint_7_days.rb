module BlazerDashboards
  module Queries
    class ApiRequestsByEndpoint7Days
      def self.sql
        <<~SQL
          select
            labels->>'controller' as controller,
            labels->>'action' as action,
            sum(value) as requests
          from metrics
          where name = 'observability.api.request.count'
            and occurred_at >= now() - interval '7 days'
          group by 1, 2
          order by requests desc
        SQL
      end
    end
  end
end
