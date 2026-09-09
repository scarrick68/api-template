module Api
  module V1
    module Users
      class UpdateContract < ApplicationContract
        attribute :id, :integer
        attribute :name, :string
        attribute :email, :string
        attribute :age, :integer
        attribute :height_ft, :integer
        attribute :height_inches, :integer
        attribute :weight_lbs, :float
        attribute :activity_level, :integer
        attribute :goal, :string
        attribute :time_zone, :string

        validates :id, numericality: { greater_than: 0 }
        validates :name, length: { minimum: 1, maximum: 255 }, allow_nil: true
        validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
        validates :age, numericality: { greater_than: 0, less_than_or_equal_to: 120 }, allow_nil: true
        validates :height_ft, numericality: { greater_than: 0, less_than_or_equal_to: 9 }, allow_nil: true
        validates :height_inches, numericality: { greater_than_or_equal_to: 0, less_than: 12 }, allow_nil: true
        validates :weight_lbs, numericality: { greater_than: 0 }, allow_nil: true
        validates :activity_level, numericality: { greater_than: 0, less_than_or_equal_to: 5 }, allow_nil: true
        validates :goal, length: { minimum: 1, maximum: 100 }, allow_nil: true
        validates :time_zone, length: { minimum: 1, maximum: 100 }, allow_nil: true
      end
    end
  end
end
