# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = ENV.fetch("DEVISE_MAILER_SENDER", "please-change-me@example.com")

  require "devise/orm/active_record"

  # Keep JSON support for API auth while allowing session-based HTML sign-in flows.
  config.navigational_formats = [ :html, :json ]
end
