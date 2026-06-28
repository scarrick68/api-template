# Base browser controller for HTML/admin surfaces and shared request log enrichment.
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # Session-authenticated browser flows share this enrichment path.
  # Devise / DTA auth controllers use their own scoped enrichment methods, however
  # DTA controllers still inherit from this base controller and it's hard to override
  # or break the inheritance chain, so we use a guard clause to avoid double-enrichment
  # and missing method errors
  def append_info_to_payload(payload)
    super

    return if devise_controller?

    payload[:admin_id] = current_admin&.id if respond_to?(:current_admin, true)
    payload[:user_id] = current_user&.id if payload[:admin_id].nil? && respond_to?(:current_user, true)
    payload[:visitor_token] = ahoy&.visitor_token if respond_to?(:ahoy, true)
  end
end
