# frozen_string_literal: true

require "active_support/inflector"

# Renames api-template internals to match a new product API app name.
class TemplateRenameCommand
  IGNORED_RENAME_PATHS = [
    "lib/template_rename_command.rb",
    "test/lib/template_rename_command_test.rb"
  ].freeze

  MODULE_REFERENCE_GLOBS = [
    "app/**/*.rb",
    "app/**/*.erb",
    "config/**/*.rb",
    "lib/**/*.rb",
    "test/**/*.rb"
  ].freeze

  # Builds a command instance with injectable CLI input and file root.
  def initialize(argv: ARGV, stdin: $stdin, stdout: $stdout, stderr: $stderr, root_path: Dir.pwd)
    @argv = argv
    @stdin = stdin
    @stdout = stdout
    @stderr = stderr
    @root_path = root_path
  end

  # Public entrypoint that validates input and applies all rewrites.
  def run
    current_module_name = detect_current_module_name
    old_name, new_name = parse_names(current_module_name)

    old_module_name = camelize(old_name)
    old_module_names = [ current_module_name, old_module_name ].compact.uniq
    product_name = new_name.sub(/-api\z/, "")
    module_name = camelize(new_name)
    old_underscored_names = [
      old_name.tr("-", "_"),
      underscore(old_module_name),
      underscore(current_module_name)
    ].compact.uniq
    underscored_name = new_name.tr("-", "_")
    api_title = "#{titleize(product_name)} API"

    rewrite_file("config/application.rb") do |content|
      content.sub(/^module\s+\w+\s*$/, "module #{module_name}")
    end

    rewrite_file("docs/openapi.yml") do |content|
      content.sub(/^(\s*title:\s*).+$/, "\\1#{api_title}")
    end

    rewrite_file("compose.yml") do |content|
      content.sub(/^(\s*container_name:\s*).+$/, "\\1#{new_name}-elasticsearch")
    end

    rewrite_file("config/deploy.yml") do |content|
      old_underscored_names
        .reject { |name| name.empty? || name == underscored_name }
        .sort_by { |name| -name.length }
        .reduce(content) { |updated, old| updated.gsub(old, underscored_name) }
    end

    rewrite_file("README.md") do |content|
      if content.start_with?("# ")
        content.sub(/^#\s+.*$/, "# #{api_title}")
      else
        "# #{api_title}\n\n#{content}"
      end
    end

    rewrite_module_references(old_names: old_module_names, new_name: module_name)
    warn_on_remaining_references(old_module_names: old_module_names, old_name: old_name)

    @stdout.puts "api template rename complete: #{new_name}"
  end

  private

  # Prints a message plus usage and exits with a non-zero status.
  def abort_with_usage(message)
    @stderr.puts(message)
    @stderr.puts("Usage: bin/template_rename <new-app-name-kebab-case>")
    @stderr.puts("   or: bin/template_rename <original-app-name-kebab-case> <new-app-name-kebab-case>")
    exit 1
  end

  # Prints usage for subsequent renames, which require current and new app names.
  def abort_with_subsequent_rename_usage(message, current_app_name: nil)
    @stderr.puts(message)
    @stderr.puts("Usage: bin/template_rename <current-app-name-kebab-case> <new-app-name-kebab-case>")
    if current_app_name && !current_app_name.empty?
      @stderr.puts("Example: bin/template_rename #{current_app_name} my-product-api")
    end
    exit 1
  end

  # Prints a warning message to emphasize non-fatal rename caveats.
  def warn_message(message)
    @stderr.puts("WARNING: #{message}")
  end

  # Enforces kebab-case naming to keep downstream replacements predictable.
  def validate_name!(name)
    return if name.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)

    abort_with_usage("Invalid app name '#{name}'. Expected kebab-case.")
  end

  # Converts kebab-case to CamelCase for Ruby module names.
  def camelize(value)
    ActiveSupport::Inflector.camelize(value.tr("-", "_"))
  end

  # Converts kebab-case to title case for docs and UI labels.
  def titleize(value)
    ActiveSupport::Inflector.titleize(value.tr("-", "_"))
  end

  # Converts CamelCase constants to snake_case for deploy identifiers.
  def underscore(value)
    return nil if value.nil? || value.empty?

    ActiveSupport::Inflector.underscore(value)
  end

  # Prompts the user to confirm a best-effort subsequent rename.
  def confirm_subsequent_rename!(current_app_name:, new_name:)
    @stderr.print("Continue rename from '#{current_app_name}' to '#{new_name}'? [y/N]: ")
    answer = @stdin.gets
    return false if answer.nil?

    answer.strip.match?(/\A(y|yes)\z/i)
  end

  # Resolves old/new names from arguments, with safe defaults for first rename.
  def parse_names(current_module_name)
    args = @argv.map(&:to_s).map(&:strip).reject(&:empty?)

    case args.length
    when 1
      new_name = args[0]
      validate_name!(new_name)

      return [ "api-template", new_name ] if current_module_name == "ApiTemplate"

      current_app_name = underscore(current_module_name)&.tr("_", "-")
      warn_message("Subsequent renames are best-effort only and have no guarantees after changes have been made to original template.")
      warn_message(
        "Detected current app name from module '#{current_module_name || 'unknown'}': #{current_app_name || 'unknown'}."
      )

      if current_app_name.nil? || current_app_name.empty?
        abort_with_subsequent_rename_usage(
          "Could not detect current app name from current module. Provide current and new names.",
          current_app_name: nil
        )
      end

      return [ current_app_name, new_name ] if confirm_subsequent_rename!(current_app_name: current_app_name, new_name: new_name)

      abort_with_subsequent_rename_usage(
        "Rename cancelled by user.",
        current_app_name: current_app_name
      )
    when 2
      old_name, new_name = args
      validate_name!(old_name)
      validate_name!(new_name)

      warn_message("Subsequent renames are best-effort only and have no guarantees after changes have been made to original template.")
      expected_module_name = camelize(old_name)
      if current_module_name && current_module_name != expected_module_name
        warn_message(
          "Current module '#{current_module_name}' does not match provided original '#{expected_module_name}'. " \
          "Proceeding with provided original name."
        )
      end

      [ old_name, new_name ]
    else
      abort_with_usage("Expected one or two app names.")
    end
  end

  # Detects the currently configured top-level app module from application.rb.
  def detect_current_module_name
    application_path = File.join(@root_path, "config/application.rb")
    return nil unless File.exist?(application_path)

    content = File.read(application_path)
    content[/^\s*module\s+([A-Za-z_]\w*)\s*$/, 1]
  end

  # Rewrites module name references across curated Ruby/ERB source files.
  def rewrite_module_references(old_names:, new_name:)
    candidates = Array(old_names).compact.uniq.reject { |name| name.empty? || name == new_name }
    return if candidates.empty?

    pattern = /(?<![A-Za-z0-9_])(?:#{candidates.map { |name| Regexp.escape(name) }.join("|")})(?![A-Za-z0-9_])/

    module_reference_files.each do |relative_path|
      next if relative_path == "config/application.rb"

      rewrite_file(relative_path) do |content|
        content.gsub(pattern, new_name)
      end
    end
  end

  # Collects candidate source files where module constants may appear.
  def module_reference_files
    MODULE_REFERENCE_GLOBS.flat_map do |glob|
      Dir.glob(File.join(@root_path, glob))
    end.filter_map do |absolute_path|
      next unless File.file?(absolute_path)

      relative_path = absolute_path.delete_prefix("#{@root_path}/")
      next if skip_reference_scan_path?(relative_path)

      relative_path
    end.uniq.sort
  end

  # Scans the project for references that still mention previous names.
  def warn_on_remaining_references(old_module_names:, old_name:)
    needles = Array(old_module_names).compact + [ old_name ]
    needles = needles.reject(&:empty?).uniq
    return if needles.empty?

    matches = remaining_reference_matches(needles)
    return if matches.empty?

    @stderr.puts("WARNING: Found remaining references to previous app names.")
    @stderr.puts("WARNING: Update these references manually, use ai to update references, or run 'git restore .' to undo all local changes.")
    @stderr.puts("WARNING: No guarantees are provided for subsequent renames after changes have been made to original template.")
    matches.each do |path, found_needles|
      @stderr.puts("WARNING: #{path} (#{found_needles.sort.join(', ')})")
    end
  end

  # Finds files still containing old module or kebab-case names.
  def remaining_reference_matches(needles)
    scan_files = Dir.glob(File.join(@root_path, "**/*"), File::FNM_DOTMATCH).filter_map do |absolute_path|
      next unless File.file?(absolute_path)

      relative_path = absolute_path.delete_prefix("#{@root_path}/")
      next if skip_reference_scan_path?(relative_path)

      relative_path
    end

    scan_files.each_with_object({}) do |relative_path, acc|
      absolute_path = File.join(@root_path, relative_path)
      content = File.read(absolute_path)
      found = needles.select { |needle| content.include?(needle) }
      next if found.empty?

      acc[relative_path] = found
    rescue ArgumentError
      # Ignore binary or invalid-encoding files in the scan.
      next
    end
  end

  # Excludes log files and other non-source artifacts from reference scans.
  def skip_reference_scan_path?(relative_path)
    relative_path.start_with?("log/") ||
      relative_path.start_with?(".git/") ||
      relative_path.start_with?("coverage/") ||
      relative_path.start_with?("tmp/") ||
      relative_path.start_with?("storage/") ||
      IGNORED_RENAME_PATHS.include?(relative_path)
  end

  # Rewrites a file only when content changes and reports updated files.
  def rewrite_file(path)
    absolute_path = File.join(@root_path, path)
    return unless File.exist?(absolute_path)

    original = File.read(absolute_path)
    updated = yield(original.dup)
    return if updated == original

    File.write(absolute_path, updated)
    @stdout.puts "updated #{path}"
  end
end
