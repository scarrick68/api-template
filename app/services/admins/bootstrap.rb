# frozen_string_literal: true

module Admins
  class Bootstrap
    class Error < StandardError; end

    MIN_PASSWORD_LENGTH = 20
    FIRST_ADMIN_ONLY_MESSAGE = "This command only bootstraps the first admin. Provision additional admins separately."

    def self.call(...)
      new(...).call
    end

    def initialize(email:, password:)
      @email = email.to_s.strip
      @password = password.to_s
    end

    def call
      validate_inputs!

      admins = Admin.order(:id).to_a
      matching_admin = admins.find { |admin| admin.email == email }

      if admins.size > 1
        return {
          status: "already_exists",
          email: matching_admin&.email || admins.first.email,
          admins_count: admins.size,
          message: FIRST_ADMIN_ONLY_MESSAGE
        }
      end

      return { status: "already_exists", email: matching_admin.email, message: FIRST_ADMIN_ONLY_MESSAGE } if matching_admin

      raise Error, "An administrator already exists with a different email. #{FIRST_ADMIN_ONLY_MESSAGE}" if admins.any?

      admin = Admin.new(email: email)
      admin.password = password
      admin.password_confirmation = password
      admin.save!

      { status: "created", email: admin.email }
    end

    private

    attr_reader :email, :password

    def validate_inputs!
      raise Error, "ADMIN_EMAIL cannot be blank" if email.empty?
      raise Error, "ADMIN_PASSWORD must be at least #{MIN_PASSWORD_LENGTH} characters. Admin password requires extra safety." if password.length < MIN_PASSWORD_LENGTH
    end
  end
end
