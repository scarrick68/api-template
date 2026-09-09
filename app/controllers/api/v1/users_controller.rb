module Api
  module V1
    class UsersController < BaseController
      before_action :authenticate_user!, except: [ :create ]

      USER_MUTABLE_PARAMS = %i[
        name
        email
        age
        height_ft
        height_inches
        weight_lbs
        activity_level
        goal
        time_zone
      ].freeze

      def create
        permitted_params = params.permit(
          *USER_MUTABLE_PARAMS,
          :password,
          :password_confirmation
        ).to_h

        contract = Api::V1::Users::CreateContract.new(
          permitted_params
        ).validate!

        authorize!(User, :create?)

        created_record = Svc::Api::V1::Users::Create.call(
          attributes: {
            name: contract.name,
            email: contract.email,
            password: contract.password,
            password_confirmation: contract.password_confirmation,
            age: contract.age,
            height_ft: contract.height_ft,
            height_inches: contract.height_inches,
            weight_lbs: contract.weight_lbs,
            activity_level: contract.activity_level,
            goal: contract.goal,
            time_zone: contract.time_zone
          }
        )

        render_serialized(
          Api::V1::UsersShowResponseBlueprint,
          {
            success: true,
            data: created_record
          },
          status: :created
        )
      end

      def index
        authorize!(User, :index?)

        contract = Api::V1::Users::IndexContract.new(
          params.permit(:page, :per_page).to_h.compact_blank
        ).validate!

        scope = Svc::Api::V1::Users::List.call

        pagy, records = paginate_scope(
          scope,
          page: contract.page,
          per_page: contract.per_page
        )

        render_serialized(
          Api::V1::UsersIndexResponseBlueprint,
          {
            success: true,
            records: records,
            meta: { pagination: pagination_meta(pagy) }
          }
        )
      end

      def me
        authorize!(current_user, :show?)

        render_serialized(
          Api::V1::UsersShowResponseBlueprint,
          {
            success: true,
            data: current_user
          }
        )
      end

      def show
        contract = Api::V1::Users::ShowContract.new(
          params.permit(:id).to_h
        ).validate!

        user_record = Svc::Api::V1::Users::Show.call(
          id: contract.id,
          scope: user_lookup_scope
        )

        unless user_record
          return render_api_error(
            type: "forbidden",
            message: "You are not authorized to perform this action",
            status: :forbidden
          )
        end

        authorize!(user_record, :show?)

        render_serialized(
          Api::V1::UsersShowResponseBlueprint,
          {
            success: true,
            data: user_record
          }
        )
      end

      def update
        permitted_params = params.permit(:id, *USER_MUTABLE_PARAMS).to_h

        contract = Api::V1::Users::UpdateContract.new(
          permitted_params
        ).validate!

        user_record = Svc::Api::V1::Users::Show.call(
          id: contract.id,
          scope: user_lookup_scope
        )

        unless user_record
          return render_api_error(
            type: "forbidden",
            message: "You are not authorized to perform this action",
            status: :forbidden
          )
        end

        authorize!(user_record, :update?)

        updated_record = Svc::Api::V1::Users::Update.call(
          user: user_record,
          attributes: permitted_params.slice(*USER_MUTABLE_PARAMS.map(&:to_s))
        )

        render_serialized(
          Api::V1::UsersShowResponseBlueprint,
          {
            success: true,
            data: updated_record
          }
        )
      end

      def destroy
        contract = Api::V1::Users::DestroyContract.new(
          params.permit(:id).to_h
        ).validate!

        user_record = Svc::Api::V1::Users::Show.call(
          id: contract.id,
          scope: user_lookup_scope
        )

        unless user_record
          return render_api_error(
            type: "forbidden",
            message: "You are not authorized to perform this action",
            status: :forbidden
          )
        end

        authorize!(user_record, :destroy?)

        deleted_record = Svc::Api::V1::Users::Destroy.call(user: user_record)

        render_serialized(
          Api::V1::UsersShowResponseBlueprint,
          {
            success: true,
            data: deleted_record
          }
        )
      end

      private

      def user_lookup_scope
        current_user&.admin? ? User.unscoped : User
      end
    end
  end
end
