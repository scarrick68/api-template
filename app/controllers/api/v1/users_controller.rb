module Api
  module V1
    class UsersController < BaseController
      before_action :authenticate_user!

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
            meta: pagination_meta(pagy)
          }
        )
      end

      def show
        contract = Api::V1::Users::ShowContract.new(
          params.permit(:id).to_h
        ).validate!

        user_record = Svc::Api::V1::Users::Show.call(id: contract.id)

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
        permitted_params = params.permit(:id, :name, :email).to_h

        contract = Api::V1::Users::UpdateContract.new(
          permitted_params
        ).validate!

        user_record = Svc::Api::V1::Users::Show.call(id: contract.id)

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
          attributes: permitted_params.slice("name", "email")
        )

        render_serialized(
          Api::V1::UsersShowResponseBlueprint,
          {
            success: true,
            data: updated_record
          }
        )
      end
    end
  end
end
