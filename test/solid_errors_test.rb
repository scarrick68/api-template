require "test_helper"

class SolidErrorsTest < ActiveSupport::TestCase
  test "records errors through Rails error reporter" do
    err_message = "solid errors test"
    assert_difference "SolidErrors::Error.count", 1 do
      Rails.error.handle { raise err_message }
    end

    error = SolidErrors::Error.last

    assert_equal "RuntimeError", error.exception_class
    assert_equal err_message, error.message
  end

  test "uses the primary database connection" do
    assert_equal(
      ActiveRecord::Base.connection_db_config.name,
      SolidErrors::Error.connection_db_config.name
    )
  end

  test "does not use a separate errors database" do
    assert_not_equal :errors,
                     Rails.application.config.solid_errors.connects_to&.dig(:database, :writing)
  end
end
