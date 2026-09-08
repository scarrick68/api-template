module Api
  module V1
    class FeaturesController < BaseController
      before_action :authenticate_user!

      def index
        authorize!(current_user, :show?)

        feature_states = Flipper.features.sort_by(&:key).each_with_object({}) do |feature, flags|
          flags[feature.key] = feature.enabled?(current_user)
        end

        render_serialized(
          Api::V1::FeaturesIndexResponseBlueprint,
          {
            success: true,
            data: feature_states
          }
        )
      end
    end
  end
end
