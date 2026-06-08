module Svc
  module Api
    module V1
      module Users
        class Show < Svc::Base
          def initialize(id:, scope: User)
            @id = id
            @scope = scope
          end

          def call
            @scope.find_by(id: @id)
          end
        end
      end
    end
  end
end
