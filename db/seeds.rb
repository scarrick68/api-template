# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# WARNING:
# - The admin seed below is development-only convenience data.
# - Do not rely on db:seed for production bootstrap.
# - Create production admin users through a controlled/manual process.
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

if Rails.env.development?
  admin_email = ENV.fetch("SEED_ADMIN_EMAIL", "admin@example.com")
  admin_password = ENV.fetch("SEED_ADMIN_PASSWORD", "password123")

  admin = Admin.find_or_initialize_by(email: admin_email)
  admin.password = admin_password
  admin.password_confirmation = admin_password
  admin.save!

  puts "Seeded development admin: #{admin_email}"
elsif Rails.env.production?
  warn "WARNING: db:seed does not create an admin in production. Use a controlled manual bootstrap process."
end
