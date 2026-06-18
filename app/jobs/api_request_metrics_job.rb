class ApiRequestMetricsJob < ApplicationJob
  queue_as :metrics

  def perform(payload)
    validated_payload = Schemas::DrySchemaValidator.validate!(
      Schemas::ApiRequestMetricsPayload,
      payload
    )

    rows = ApiRequestMetricsBuilder.call(validated_payload)

    rows.each do |row|
      Schemas::DrySchemaValidator.validate!(
        Schemas::ApiRequestMetricRow,
        row.except(:created_at, :updated_at)
      )
    end

    Metric.insert_all!(rows)
  end
end
