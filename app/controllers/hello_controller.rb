class HelloController < ApplicationController
  def show
    name = params[:name].presence || "world"
    cache_key = "hello:greeting:#{name}"

    message = Rails.cache.read(cache_key)
    cached = message.present?

    unless cached
      message = "Hello, #{name}!"
      Rails.cache.write(cache_key, message, expires_in: 10.minutes)
    end

    render json: {
      success: true,
      message: message,
      cached: cached
    }
  end
end
