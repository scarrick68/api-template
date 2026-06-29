source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
gem "blueprinter"
gem "pagy", "~> 9.0"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"
gem "rack-attack", "~> 6.8"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  gem "bullet", "~> 8.1"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "letter_opener_web"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "factory_bot_rails"
  gem "mocha"
  gem "skooma", "~> 0.4.0"
  gem "foreman", "~> 0.90.0"
  gem "simplecov", require: false
end

gem "devise_token_auth", github: "lynndylanhurley/devise_token_auth", branch: "master"

gem "devise", "~> 5.0"

gem "pghero", "~> 3.8"

gem "blazer", "~> 3.4"

gem "ahoy_matey", "~> 5.5"

# Text search
gem "searchkick", "~> 6.1"
gem "elasticsearch", "~> 9.4"
gem "searchjoy", "~> 1.5"
# Perfomance improvements for Searchkick and Searchjoy
gem "typhoeus", "~> 1.6"

gem "mission_control-jobs", "~> 1.1"

gem "solid_errors", "~> 0.7.0"

gem "field_test", "~> 1.0"

gem "flipper", "~> 1.4"
gem "flipper-active_record", "~> 1.4"
gem "flipper-ui", "~> 1.4"

gem "dry-schema", "~> 1.16"

gem "rollups", "~> 0.6.0"

gem "rubycritic", "~> 5.0", groups: [ :development, :test ]

gem "avo", "~> 3.32"

gem "lograge", "~> 0.14.0"

gem "strong_migrations", "~> 2.8"
