class Metric < ApplicationRecord
  include Metrics::ApiRequestMetricNames

  METRIC_TYPES = %w[counter histogram gauge].freeze

  VALID_PREFIXES = %w[
    observability
  ].freeze

  validates :occurred_at, :name, :metric_type, :value, presence: true
  validates :metric_type, inclusion: { in: METRIC_TYPES }
  validate :name_has_reserved_prefix

  private

  def name_has_reserved_prefix
    prefix = name.to_s.split(".").first
    errors.add(:name, "must start with a reserved namespace") unless VALID_PREFIXES.include?(prefix)
  end
end
