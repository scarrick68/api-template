module Api
  module V1
    module Users
      class CreateContract < ApplicationContract
        attribute :name, :string
        attribute :email, :string
        attribute :password, :string
        attribute :password_confirmation, :string
        attribute :age, :integer
        attribute :height_ft, :integer
        attribute :height_inches, :integer
        attribute :weight_lbs, :float
        attribute :activity_level, :integer
        attribute :goal, :string
        attribute :time_zone, :string

        validates :name, length: { minimum: 1, maximum: 255 }, allow_nil: true
        validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
        validates :password, presence: true, length: { minimum: 8 }
        validates :password_confirmation, presence: true
        validates :age, numericality: { greater_than: 0, less_than_or_equal_to: 120 }, allow_nil: true
        validates :height_ft, numericality: { greater_than: 0, less_than_or_equal_to: 9 }, allow_nil: true
        validates :height_inches, numericality: { greater_than_or_equal_to: 0, less_than: 12 }, allow_nil: true
        validates :weight_lbs, numericality: { greater_than: 0 }, allow_nil: true
        validates :activity_level, numericality: { greater_than: 0, less_than_or_equal_to: 5 }, allow_nil: true
        validates :goal, length: { minimum: 1, maximum: 100 }, allow_nil: true
        validates :time_zone, length: { minimum: 1, maximum: 100 }, allow_nil: true
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
