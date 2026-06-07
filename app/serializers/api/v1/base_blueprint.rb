module Api
  module V1
    class BaseBlueprint < Blueprinter::Base
      field :success
      field :request_id
    end
  end
end
