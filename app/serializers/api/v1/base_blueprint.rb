module Api
  module V1
    class BaseBlueprint < Blueprinter::Base
      field :success
      field :request_id
      field :meta do |payload|
        payload[:meta] || {}
      end
    end
  end
end
