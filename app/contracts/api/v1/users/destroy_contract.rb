module Api
  module V1
    module Users
      class DestroyContract < ApplicationContract
        attribute :id, :integer

        validates :id, numericality: { greater_than: 0 }
      end
    end
  end
end
