require "test_helper"

class ActiveJobAdapterTest < ActiveSupport::TestCase
  test "active job uses good job adapter" do
    assert_equal :good_job, Rails.application.config.active_job.queue_adapter
  end
end
