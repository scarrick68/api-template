module Svc
  module Api
    module V1
      module Users
        class Destroy < Svc::Base
          def initialize(user:)
            @user = user
          end

          def call
            return @user if @user.deleted_at.present?

            @user.update!(deleted_at: Time.current)
            @user
          end
        end
      end
    end
  end
end
