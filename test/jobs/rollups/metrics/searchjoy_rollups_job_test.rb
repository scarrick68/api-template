require "test_helper"

class SearchjoyRollupsJobTest < ActiveJob::TestCase
  test "builds searchjoy rollups for window" do
    window_start = Time.zone.parse("2026-06-18 00:00:00 UTC")
    window_end = window_start + 1.day

    Searchjoy::Search.create!(
      query: "Books",
      normalized_query: "books",
      search_type: "User",
      created_at: window_start + 1.hour,
      converted_at: nil
    )

    Searchjoy::Search.create!(
      query: "Books",
      normalized_query: "books",
      search_type: "User",
      created_at: window_start + 2.hours,
      converted_at: window_start + 2.hours
    )

    Searchjoy::Search.create!(
      query: "Shoes",
      normalized_query: "shoes",
      search_type: "User",
      created_at: window_start + 3.hours,
      converted_at: nil
    )

    Searchjoy::Search.create!(
      query: "Outside Window",
      normalized_query: "outside-window",
      search_type: "User",
      created_at: window_start - 2.days,
      converted_at: nil
    )

    Searchjoy::SearchjoyRollupsJob.perform_now(
      period: "day",
      window_start: window_start,
      window_end: window_end
    )

    assert_in_delta 3.0, rollup_value("searchjoy.searches", "day", window_start, {}), 0.001
    assert_in_delta 2.0, rollup_value("searchjoy.searches.by_query", "day", window_start, { "query" => "books" }), 0.001
    assert_in_delta 1.0, rollup_value("searchjoy.searches.by_query", "day", window_start, { "query" => "shoes" }), 0.001
    assert_in_delta(0.333, rollup_value("searchjoy.searches.conversion_rate", "day", window_start, {}), 0.001)
  end

  test "supports hourly rollups" do
    window_start = Time.zone.parse("2026-06-18 10:00:00 UTC")
    window_end = window_start + 1.hour

    Searchjoy::Search.create!(
      query: "Books",
      normalized_query: "books",
      search_type: "User",
      created_at: window_start + 5.minutes,
      converted_at: nil
    )

    Searchjoy::SearchjoyRollupsJob.perform_now(
      period: "hour",
      window_start: window_start,
      window_end: window_end
    )

    assert_in_delta 1.0, rollup_value("searchjoy.searches", "hour", window_start, {}), 0.001
  end

  private

  def rollup_value(name, interval, time, dimensions)
    Rollup.find_by!(
      name: name,
      interval: interval,
      time: time,
      dimensions: dimensions
    ).value
  end
end
