require "test_helper"

module Svc
  module Api
    module V1
      module Hello
        class ShowTest < ActiveSupport::TestCase
          setup do
            assert ActiveRecord::Base.connection.data_source_exists?("solid_cache_entries"),
                   "solid_cache_entries table is missing; run test DB migrations"

            @original_cache = Rails.cache
            Rails.cache = ActiveSupport::Cache.lookup_store(:solid_cache_store, namespace: "svc_hello_show_test")
            ActiveRecord::Base.connection.execute("DELETE FROM solid_cache_entries")
          end

          teardown do
            Rails.cache = @original_cache
          end

          test "returns computed greeting and reports cache miss on first call" do
            name = "svc-#{SecureRandom.hex(4)}"

            result = Show.call(name: name)

            assert_equal "Hello, #{name}!", result[:message]
            assert_equal false, result[:cached]
            assert_equal "Hello, #{name}!", Rails.cache.read("hello:greeting:#{name}")
          end

          test "returns cached greeting when present" do
            name = "svc-#{SecureRandom.hex(4)}"
            Rails.cache.write("hello:greeting:#{name}", "Hello, #{name}!", expires_in: 10.minutes)

            result = Show.call(name: name)

            assert_equal "Hello, #{name}!", result[:message]
            assert_equal true, result[:cached]
          end

          test "defaults blank names to world" do
            result = Show.call(name: "")

            assert_equal "Hello, world!", result[:message]
            assert_equal false, result[:cached]
          end
        end
      end
    end
  end
end
