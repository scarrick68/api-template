module Api
  module V1
    class HelloController < BaseController
      def show
        result = Svc::Api::V1::Hello::Show.call(name: params[:name])

        render json: {
          success: true,
          message: result[:message],
          cached: result[:cached]
        }
      end
    end
  end
end
