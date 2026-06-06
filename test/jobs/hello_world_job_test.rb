require "test_helper"

class HelloWorldJobTest < ActiveJob::TestCase
  test "perform_now returns hello message" do
    assert_equal "Hello, World!", HelloWorldJob.perform_now
    assert_equal "Hello, Rails!", HelloWorldJob.perform_now("Rails")
  end

  test "perform_later enqueues and performs" do
    assert_enqueued_with(job: HelloWorldJob, args: [ "Queue" ]) do
      HelloWorldJob.perform_later("Queue")
    end

    perform_enqueued_jobs

    assert_performed_jobs 1
  end

  test "solid queue adapter writes to solid_queue_jobs table" do
    assert ActiveRecord::Base.connection.data_source_exists?("solid_queue_jobs"),
           "solid_queue_jobs table is missing; run test DB migrations"

    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :solid_queue

    before_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM solid_queue_jobs").to_i

    HelloWorldJob.perform_later("DB")

    after_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM solid_queue_jobs").to_i
    assert_equal before_count + 1, after_count
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter
  end
end
