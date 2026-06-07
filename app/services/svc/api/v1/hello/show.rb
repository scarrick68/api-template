module Svc
  module Api
    module V1
      module Hello
        class Show < Svc::Base
          def initialize(name:)
            @name = name
          end

          def call
            resolved_name = @name.presence || "world"
            cache_key = "hello:greeting:#{resolved_name}"

            message = Rails.cache.read(cache_key)
            cached = message.present?

            unless cached
              message = "Hello, #{resolved_name}!"
              Rails.cache.write(cache_key, message, expires_in: 10.minutes)
            end

            {
              message: message,
              cached: cached
            }
          end
        end
      end
    end
  end
end
