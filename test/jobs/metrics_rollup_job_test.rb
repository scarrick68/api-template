require "test_helper"

class MetricsRollupJobTest < ActiveJob::TestCase
  test "delegates to api observability, endpoint, and searchjoy rollup jobs" do
    window_start = Time.zone.parse("2026-06-18 10:00:00 UTC")
    window_end = window_start + 1.hour

    Metrics::Rollups::ApiObservabilityJob.expects(:perform_now).with(
      period: "hour",
      window_start: window_start,
      window_end: window_end
    )

    Metrics::Rollups::ApiEndpointsJob.expects(:perform_now).with(
      period: "hour",
      window_start: window_start,
      window_end: window_end
    )

    Searchjoy::SearchjoyRollupsJob.expects(:perform_now).with(
      period: "hour",
      window_start: window_start,
      window_end: window_end
    )

    Metrics::Rollups::MetricsRollupJob.perform_now(
      period: "hour",
      window_start: window_start,
      window_end: window_end
    )
  end

  test "passes through defaults when optional window args are omitted" do
    Metrics::Rollups::ApiObservabilityJob.expects(:perform_now).with(
      period: "day",
      window_start: nil,
      window_end: nil
    )

    Metrics::Rollups::ApiEndpointsJob.expects(:perform_now).with(
      period: "day",
      window_start: nil,
      window_end: nil
    )

    Searchjoy::SearchjoyRollupsJob.expects(:perform_now).with(
      period: "day",
      window_start: nil,
      window_end: nil
    )

    Metrics::Rollups::MetricsRollupJob.perform_now(period: "day")
  end
end
