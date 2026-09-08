module Api
  module V1
    class FeaturesIndexResponseBlueprint < BaseBlueprint
      field :data do |payload|
        payload[:data]
      end
    end
  end
end
