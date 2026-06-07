module Api
  class RequestValidationError < StandardError
    attr_reader :details

    def initialize(message = "Request validation failed", details: [])
      @details = Array(details).compact
      super(message)
    end
  end
end
