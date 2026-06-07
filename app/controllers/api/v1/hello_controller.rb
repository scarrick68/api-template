module Api
  module V1
    class HelloController < BaseController
      def show
        contract = Api::V1::Hello::ShowContract.new(name: params[:name]).validate!
        result = Svc::Api::V1::Hello::Show.call(name: contract.name)

        render json: {
          success: true,
          message: result[:message],
          cached: result[:cached]
        }
      end
    end
  end
end
