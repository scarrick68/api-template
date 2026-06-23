# frozen_string_literal: true

require "yaml"

namespace :yaml do
  desc "Validate YAML files"
  task :lint, [ :path ] do |_task, args|
    path = args[:path] || "**/*.{yml,yaml}"

    files = Dir.glob(path)
    abort("No YAML files found for #{path}") if files.empty?

    files.each do |file|
      YAML.load_file(file)
      puts "✓ #{file}"
    rescue Psych::SyntaxError => e
      warn "✗ #{file}"
      warn e.message
      exit 1
    end
  end
end
