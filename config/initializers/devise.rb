# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = ENV.fetch("DEVISE_MAILER_SENDER", "please-change-me@example.com")

  require "devise/orm/active_record"

  # API-only apps should treat JSON as navigational to avoid flash/session assumptions.
  config.navigational_formats = [ :json ]
end
