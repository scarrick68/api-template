# frozen_string_literal: true

require "json"

namespace :app do
  desc "Create the initial administrator account for production bootstrap"
  task bootstrap_admin: :environment do
    result = Admins::Bootstrap.call(
      email: ENV.fetch("ADMIN_EMAIL", ""),
      password: ENV.fetch("ADMIN_PASSWORD", "")
    )
    puts "ADMIN_BOOTSTRAP_RESULT=#{JSON.generate(result)}"
  rescue Admins::Bootstrap::Error => e
    abort e.message
  end
end
