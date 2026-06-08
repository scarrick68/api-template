module Api
  module V1
    module Users
      class CreateContract < ApplicationContract
        attribute :name, :string
        attribute :email, :string
        attribute :password, :string
        attribute :password_confirmation, :string

        validates :name, length: { minimum: 1, maximum: 255 }, allow_nil: true
        validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
        validates :password, presence: true, length: { minimum: 8 }
        validates :password_confirmation, presence: true
        validate :password_confirmation_matches_password

        private

        def password_confirmation_matches_password
          return if password_confirmation.blank? || password.blank?
          return if password_confirmation == password

          errors.add(:password_confirmation, "must be equal to password")
        end
      end
    end
  end
end
