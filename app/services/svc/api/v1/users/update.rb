module Svc
  module Api
    module V1
      module Users
        class Update < Svc::Base
          def initialize(user:, attributes: {})
            @user = user
            @attributes = attributes
          end

          def call
            sanitized_attributes = @attributes.compact
            return @user if sanitized_attributes.empty?

            @user.update!(sanitized_attributes)
            @user
          end
        end
      end
    end
  end
end
