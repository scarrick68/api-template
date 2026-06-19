require "test_helper"

class MetricsRetentionJobTest < ActiveJob::TestCase
  test "deletes raw metrics older than 30 days" do
    stale_metric = create(:metric, occurred_at: 31.days.ago)
    recent_metric = create(:metric, occurred_at: 29.days.ago)

    MetricsRetentionJob.perform_now

    assert_not Metric.exists?(stale_metric.id)
    assert Metric.exists?(recent_metric.id)
  end

  test "deletes hourly rollups older than 90 days and keeps recent" do
    stale_hourly = create_rollup(interval: "hour", time: 91.days.ago.beginning_of_hour)
    recent_hourly = create_rollup(interval: "hour", time: 89.days.ago.beginning_of_hour)

    MetricsRetentionJob.perform_now

    assert_not Rollup.exists?(stale_hourly.id)
    assert Rollup.exists?(recent_hourly.id)
  end

  test "deletes daily rollups older than two years and keeps recent" do
    stale_daily = create_rollup(interval: "day", time: 2.years.ago - 1.day)
    recent_daily = create_rollup(interval: "day", time: 1.year.ago)

    MetricsRetentionJob.perform_now

    assert_not Rollup.exists?(stale_daily.id)
    assert Rollup.exists?(recent_daily.id)
  end

  private

  def create_rollup(interval:, time:, name: "observability.api.requests.total", dimensions: {}, value: 1.0)
    Rollup.create!(
      name: name,
      interval: interval,
      time: time,
      dimensions: dimensions,
      value: value
    )
  end
end
