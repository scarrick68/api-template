module Svc
  module Api
    module V1
      module Users
        class Create < Svc::Base
          def initialize(attributes: {})
            @attributes = attributes
          end

          def call
            user = User.new(@attributes.compact)
            user.save!
            user
          end
        end
      end
    end
  end
end
