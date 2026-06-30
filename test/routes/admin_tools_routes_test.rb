require "test_helper"

class AdminToolsRoutesTest < ActiveSupport::TestCase
  test "admin tools dashboard route is mounted" do
    assert_route_mounted("/admin/tools")
  end

  test "avo route is mounted" do
    assert_route_mounted("/avo")
  end

  test "pghero route is mounted" do
    assert_route_mounted("/pghero")
  end

  test "good job route is mounted" do
    assert_route_mounted("/good_job")
  end

  test "solid errors route is mounted" do
    assert_route_mounted("/solid_errors")
  end

  test "field test route is mounted" do
    assert_route_mounted("/field_test")
  end

  test "flipper route is mounted" do
    assert_route_mounted("/flipper")
  end

  test "blazer route is mounted" do
    assert_route_mounted("/blazer")
  end

  test "searchjoy route is mounted" do
    assert_route_mounted("/searchjoy")
  end

  test "docs route is mounted" do
    assert_route_mounted("/docs")
  end

  test "openapi route is mounted" do
    assert_route_mounted("/openapi.yml")
  end

  private

  def assert_route_mounted(prefix)
    assert route_mounted?(prefix), "Expected #{prefix} to be mounted"
  end

  def route_mounted?(prefix)
    Rails.application.routes.routes.any? do |route|
      route.path.spec.to_s.match?(
        %r{\A#{Regexp.escape(prefix)}(?:/|\(|$)}
      )
    end
  end
end
