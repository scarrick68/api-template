module Api
  module V1
    # Synchronizes authenticated mobile/web push installations.
    class PushDevicesController < BaseController
      before_action :authenticate_user!

      def create
        authorize!(PushDevice, :create?)

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
        updates = {
          user: current_user,
          active: true,
          last_registered_at: Time.current
        }

        if record.new_record? || attributes.key?(:platform)
          updates[:platform] = normalized_platform(attributes[:platform])
        end

        if attributes.key?(:app_version)
          updates[:app_version] = attributes[:app_version]
        end

        if attributes.key?(:build_version)
          updates[:build_version] = attributes[:build_version]
        end

        record.assign_attributes(updates)
        record.save!

        render_serialized(Api::V1::BaseBlueprint, { success: true }, status: :accepted)
      end

      def destroy
        authorize!(PushDevice, :destroy?)

        token = params[:push_token].to_s.strip

        if token.empty?
          return render_api_error(
            type: "bad_request",
            message: "push_token is required",
            status: :bad_request
          )
        end

        device = PushDevice.find_by(push_token: token)

        if device.nil? || device.user_id != current_user.id
          return render_api_error(
            type: "forbidden",
            message: "You are not authorized to perform this action",
            status: :forbidden
          )
        end

        device.update!(active: false)

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
