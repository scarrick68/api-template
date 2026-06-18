require "test_helper"

class MetricTest < ActiveSupport::TestCase
  test "is valid with required fields and reserved prefix" do
    metric = Metric.new(
      occurred_at: Time.current,
      name: Metric::API_REQUEST_COUNT,
      metric_type: "counter",
      value: 1,
      properties: { method: "GET" }
    )

    assert metric.valid?
  end

  test "requires occurred_at" do
    metric = Metric.new(name: Metric::API_REQUEST_COUNT, metric_type: "counter", value: 1)

    assert_equal false, metric.valid?
    assert_includes metric.errors[:occurred_at], "can't be blank"
  end

  test "requires name" do
    metric = Metric.new(occurred_at: Time.current, metric_type: "counter", value: 1)

    assert_equal false, metric.valid?
    assert_includes metric.errors[:name], "can't be blank"
  end

  test "rejects name outside reserved namespace" do
    metric = Metric.new(
      occurred_at: Time.current,
      metric_type: "counter",
      value: 1,
      name: "analytics.api.request"
    )

    assert_equal false, metric.valid?
    assert_includes metric.errors[:name], "must start with a reserved namespace"
  end

  test "requires metric_type" do
    metric = Metric.new(
      occurred_at: Time.current,
      name: Metric::API_REQUEST_COUNT,
      value: 1
    )

    assert_equal false, metric.valid?
    assert_includes metric.errors[:metric_type], "can't be blank"
  end

  test "requires value" do
    metric = Metric.new(
      occurred_at: Time.current,
      name: Metric::API_REQUEST_COUNT,
      metric_type: "counter"
    )

    assert_equal false, metric.valid?
    assert_includes metric.errors[:value], "can't be blank"
  end

  test "rejects unsupported metric_type" do
    metric = Metric.new(
      occurred_at: Time.current,
      name: Metric::API_REQUEST_COUNT,
      metric_type: "timer",
      value: 1
    )

    assert_equal false, metric.valid?
    assert_includes metric.errors[:metric_type], "is not included in the list"
  end
end
