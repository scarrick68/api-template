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
    end
  end
end
