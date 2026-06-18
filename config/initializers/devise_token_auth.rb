# frozen_string_literal: true

# frozen_string_literal: true

DeviseTokenAuth.setup do |config|
  # Rotates access-token after each successful authenticated request.
  # More secure, but clients must persist updated auth headers from responses.
  config.change_headers_on_each_request = true

  # Require re-authentication after this duration.
  config.token_lifespan = 2.weeks

  # Keep tests fast; use normal BCrypt-ish cost outside test.
  config.token_cost = Rails.env.test? ? 4 : 10

  # Limit long-lived device/session sprawl per user.
  config.max_number_of_devices = 10

  # Allows near-simultaneous requests to reuse the same token.
  config.batch_request_buffer_throttle = 5.seconds

  # Do not mix DTA with standard Devise session behavior.
  # Admins use separate Devise session auth; Users use DTA token auth.
  config.enable_standard_devise_support = false

  # Only set this true if User includes :confirmable and the app is ready
  # to send confirmation emails.
  config.send_confirmation_email = true

  # Keep default header names for compatibility with DTA clients/helpers.
  config.headers_names = {
    'authorization': "Authorization",
    'access-token': "access-token",
    'client': "client",
    'expiry': "expiry",
    'uid': "uid",
    'token-type': "token-type"
  }
end
