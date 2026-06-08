# frozen_string_literal: true

class Rack::Attack
  AUTH_SIGN_IN_LIMIT = ENV.fetch("THROTTLE_AUTH_SIGN_IN_LIMIT", "10").to_i
  AUTH_SIGN_IN_PERIOD = ENV.fetch("THROTTLE_AUTH_SIGN_IN_PERIOD", "60").to_i.seconds

  AUTH_SIGN_UP_LIMIT = ENV.fetch("THROTTLE_AUTH_SIGN_UP_LIMIT", "10").to_i
  AUTH_SIGN_UP_PERIOD = ENV.fetch("THROTTLE_AUTH_SIGN_UP_PERIOD", "60").to_i.seconds

  USERS_WRITE_LIMIT = ENV.fetch("THROTTLE_USERS_WRITE_LIMIT", "15").to_i
  USERS_WRITE_PERIOD = ENV.fetch("THROTTLE_USERS_WRITE_PERIOD", "60").to_i.seconds

  throttle("auth/sign_in/ip", limit: AUTH_SIGN_IN_LIMIT, period: AUTH_SIGN_IN_PERIOD) do |req|
    req.ip if req.path == "/auth/sign_in" && req.post?
  end

  throttle("auth/sign_up/ip", limit: AUTH_SIGN_UP_LIMIT, period: AUTH_SIGN_UP_PERIOD) do |req|
    req.ip if req.path == "/auth" && req.post?
  end

  throttle("users/write/ip", limit: USERS_WRITE_LIMIT, period: USERS_WRITE_PERIOD) do |req|
    next unless req.path.start_with?("/api/v1/users")
    next unless %w[POST PUT PATCH DELETE].include?(req.request_method)

    req.ip
  end

  ### Custom Throttle Response ###

  # By default, Rack::Attack returns an HTTP 429 for throttled responses,
  # which is just fine.
  #
  # If you want to return 503 so that the attacker might be fooled into
  # believing that they've successfully broken your app (or you just want to
  # customize the response), then uncomment these lines.
  # From their default config docs. Can be modified later.
  # self.throttled_responder = lambda do |env|
  #  [ 503,  # status
  #    {},   # headers
  #    ['']] # body
  # end
end

Rails.application.config.middleware.use Rack::Attack
