module Metrics
  module RollupHelpers
    VALID_PERIODS = %w[hour day].freeze

    RollupWindow = Data.define(:period, :start_time, :end_time)

    private

    def build_window(period:, window_start:, window_end:)
      period = period.to_s

      unless VALID_PERIODS.include?(period)
        raise ArgumentError, "period must be one of: #{VALID_PERIODS.join(', ')}"
      end

      start_time = normalize_time(window_start) || default_start_time(period)
      end_time = normalize_time(window_end) || default_end_time(period)

      raise ArgumentError, "window_end must be after window_start" unless end_time > start_time

      RollupWindow.new(period, start_time, end_time)
    end

    def default_start_time(period)
      period == "day" ? 1.day.ago.beginning_of_day : 1.hour.ago.beginning_of_hour
    end

    def default_end_time(period)
      period == "day" ? Time.current.beginning_of_day : Time.current.beginning_of_hour
    end

    def normalize_time(value)
      return nil if value.nil?
      return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)

      Time.zone.parse(value.to_s)
    end

    def upsert_rollup(name:, window:, value:, dimensions: {})
      return if value.nil?

      Rollup.upsert(
        {
          name: name,
          interval: window.period,
          time: window.start_time,
          dimensions: dimensions.stringify_keys,
          value: value.to_f
        },
        unique_by: :index_rollups_on_name_and_interval_and_time_and_dimensions
      )
    end

    def p95(scope)
      scope.pick(Arel.sql("percentile_cont(0.95) within group (order by value)"))
    end

    def controller_sql
      Arel.sql("labels->>'controller'")
    end

    def action_sql
      Arel.sql("labels->>'action'")
    end
  end
end
