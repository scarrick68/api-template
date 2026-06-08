module Api
  module V1
    module Users
      class IndexContract < ApplicationContract
        attribute :page, :integer, default: 1
        attribute :per_page, :integer, default: 25

        validates :page, numericality: { greater_than: 0 }
        validates :per_page, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
      end
    end
  end
end
