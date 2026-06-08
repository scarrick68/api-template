module Svc
  module Api
    module V1
      module Users
        class List < Svc::Base
          def initialize(scope: User.all)
            @scope = scope
          end

          def call
            @scope.order(created_at: :desc)
          end
        end
      end
    end
  end
end
