module Api
  module V1
    # Synchronizes authenticated mobile/web push installations.
    class PushDevicesController < BaseController
      before_action :authenticate_user!

      def create
        attributes = push_device_create_params
        token = attributes[:push_token].to_s.strip

        if token.empty?
          return render_api_error(
            type: "bad_request",
            message: "push_token is required",
            status: :bad_request
          )
        end

        record = PushDevice.find_or_initialize_by(push_token: token)
        record.assign_attributes(
          user: current_user,
          platform: normalized_platform(attributes[:platform]),
          app_version: attributes[:app_version],
          build_version: attributes[:build_version],
          active: true,
          last_registered_at: Time.current
        )
        record.save!

        render_serialized(Api::V1::BaseBlueprint, { success: true }, status: :accepted)
      end

      def destroy
        token = params[:push_token].to_s.strip

        if token.present?
          device = PushDevice.find_by(push_token: token)

          if device.nil? || device.user_id != current_user.id
            return render_api_error(
              type: "forbidden",
              message: "You are not authorized to perform this action",
              status: :forbidden
            )
          end

          device.update!(active: false)

          return render_serialized(Api::V1::BaseBlueprint, { success: true }, status: :accepted)
        end

        scope = current_user.push_devices
        scope.update_all(active: false, updated_at: Time.current)

        render_serialized(Api::V1::BaseBlueprint, { success: true }, status: :accepted)
      end

      private

      def push_device_create_params
        params.permit(:push_token, :platform, :app_version, :build_version).to_h.deep_symbolize_keys
      end

      def normalized_platform(platform)
        value = platform.to_s.strip.downcase
        return value if %w[ios android web].include?(value)

        "unknown"
      end
    end
  end
end
