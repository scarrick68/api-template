class Metric < ApplicationRecord
  VALID_PREFIXES = %w[
    observability
  ].freeze

  validates :occurred_at, :name, presence: true
  validate :name_has_reserved_prefix

  private

  def name_has_reserved_prefix
    prefix = name.to_s.split(".").first
    errors.add(:name, "must start with a reserved namespace") unless VALID_PREFIXES.include?(prefix)
  end
end
