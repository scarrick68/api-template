require "test_helper"

class MetricTest < ActiveSupport::TestCase
  test "is valid with required fields and reserved prefix" do
    metric = Metric.new(
      occurred_at: Time.current,
      name: "observability.api.request",
      properties: { method: "GET" }
    )

    assert metric.valid?
  end

  test "requires occurred_at" do
    metric = Metric.new(name: "observability.api.request")

    assert_equal false, metric.valid?
    assert_includes metric.errors[:occurred_at], "can't be blank"
  end

  test "requires name" do
    metric = Metric.new(occurred_at: Time.current)

    assert_equal false, metric.valid?
    assert_includes metric.errors[:name], "can't be blank"
  end

  test "rejects name outside reserved namespace" do
    metric = Metric.new(
      occurred_at: Time.current,
      name: "analytics.api.request"
    )

    assert_equal false, metric.valid?
    assert_includes metric.errors[:name], "must start with a reserved namespace"
  end
end
