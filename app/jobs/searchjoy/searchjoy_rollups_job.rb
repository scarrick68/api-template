module Searchjoy
  class SearchjoyRollupsJob < ApplicationJob
    include Metrics::RollupHelpers

    queue_as :metrics

    ROLLUPS = {
      searches: "searchjoy.searches",
      searches_by_query: "searchjoy.searches.by_query",
      conversion_rate: "searchjoy.searches.conversion_rate"
    }.freeze

    def perform(period: "day", window_start: nil, window_end: nil)
      window = build_window(period: period, window_start: window_start, window_end: window_end)
      scope = Searchjoy::Search.where(created_at: window.start_time...window.end_time)

      scope.rollup(ROLLUPS[:searches], interval: window.period)

      scope.group(:normalized_query)
        .rollup(ROLLUPS[:searches_by_query], interval: window.period, dimension_names: [ "query" ])

      scope.rollup(ROLLUPS[:conversion_rate], interval: window.period) do |relation|
        relation.average("(converted_at IS NOT NULL)::int")
      end
    end
  end
end
