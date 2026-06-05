class TestErrorsController < ApplicationController
  def parameter_missing
    params.require(:widget)
    head :ok
  end

  def bad_request
    raise ActionController::BadRequest, "invalid request"
  end

  def not_found
    User.find(0)
  end

  def record_invalid
    User.create!
  end

  def record_not_saved
    user = User.new
    raise ActiveRecord::RecordNotSaved.new("Failed to save record", user)
  end

  def internal
    raise "boom"
  end
end
