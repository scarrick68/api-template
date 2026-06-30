# frozen_string_literal: true

class AdminToolsController < ApplicationController
  FRIENDLY_NAMES = {
    "/admin/tools" => "Admin Dashboard",
    "/avo" => "Avo",
    "/pghero" => "PgHero",
    "/blazer" => "Blazer",
    "/good_job" => "GoodJob",
    "/solid_errors" => "Solid Errors",
    "/field_test" => "Field Test",
    "/flipper" => "Flipper",
    "/searchjoy" => "Searchjoy",
    "/letter_opener" => "Letter Opener"
  }.freeze

  def index
    @tool_links = tool_paths.map { |path| [ friendly_name(path), path ] }
  end

  private

  def tool_paths
    paths = Rails.application.routes.routes.filter_map do |route|
      normalized_path = normalize_path(route.path.spec.to_s)
      next unless normalized_path
      next unless FRIENDLY_NAMES.key?(normalized_path)

      normalized_path
    end

    paths.uniq.sort_by { |path| path == "/admin/tools" ? "0" : path }
  end

  def normalize_path(raw_path)
    clean = raw_path.to_s.sub(/\(.*/, "")
    return if clean.blank?

    segments = clean.delete_prefix("/").split("/")
    return if segments.empty?

    return "/admin/tools" if segments.first == "admin" && segments[1] == "tools"

    "/#{segments.first}"
  end

  def friendly_name(path)
    FRIENDLY_NAMES[path] || path.delete_prefix("/").tr("_", " ").split.map(&:capitalize).join(" ")
  end
end
