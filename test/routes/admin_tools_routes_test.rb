# test/routes/admin_tools_routes_test.rb

require "test_helper"

class AdminToolsRoutesTest < ActiveSupport::TestCase
  test "pghero route is mounted" do
    route = Rails.application.routes.routes.find do |r|
      r.path.spec.to_s.start_with?("/pghero")
    end

    assert route, "Expected /pghero to be mounted"
  end

  test "mission control jobs route is mounted" do
    route = Rails.application.routes.routes.find do |r|
      r.path.spec.to_s.start_with?("/jobs")
    end

    assert route, "Expected /jobs to be mounted"
  end
end
