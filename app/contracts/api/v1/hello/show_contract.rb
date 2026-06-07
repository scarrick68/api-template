module Api
  module V1
    module Hello
      class ShowContract < ApplicationContract
        attribute :name, :string

        validates :name, length: { maximum: 50 }, allow_blank: true
      end
    end
  end
end
