# Thin structured event logger that wraps Rails.logger for application-level events.
module AppEvent
  class << self
    def info(name, **payload)
      emit(:info, name, payload)
    end

    def warn(name, **payload)
      emit(:warn, name, payload)
    end

    def error(name, **payload)
      emit(:error, name, payload)
    end

    private

    def parameter_filter
      @parameter_filter ||= ActiveSupport::ParameterFilter.new(
        Rails.application.config.filter_parameters
      )
    end

    def filtered_payload(payload)
      parameter_filter.filter(payload)
    end

    def build(name, payload)
      {
        timestamp: Time.current.utc.iso8601(3),
        severity: name.to_s.upcase,
        event: name
      }.merge(filtered_payload(payload))
    end

    def emit(level, name, payload)
      entry = build(name, payload).merge(severity: level.to_s.upcase)

      Rails.logger.public_send(level, entry.to_json)
    end
  end
end
