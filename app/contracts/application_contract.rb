class ApplicationContract
  include ActiveModel::Model
  include ActiveModel::Attributes

  class Invalid < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = Array(errors)
      super("Validation failed")
    end
  end

  def validate!
    return self if valid?

    raise Invalid.new(errors.full_messages)
  end
end
