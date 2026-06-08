module Api
  module V1
    module Users
      class UpdateContract < ApplicationContract
        attribute :id, :integer
        attribute :name, :string
        attribute :email, :string

        validates :id, numericality: { greater_than: 0 }
        validates :name, length: { minimum: 1, maximum: 255 }, allow_nil: true
        validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
      end
    end
  end
end
