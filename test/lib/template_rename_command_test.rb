require "test_helper"
require "fileutils"
require "tmpdir"
require "stringio"

class TemplateRenameCommandTest < ActiveSupport::TestCase
  test "rewrites api template files for a valid app name" do
    Dir.mktmpdir("api-template-rename-test") do |tmpdir|
      write_fixture_files(tmpdir)

      stdout = StringIO.new
      stderr = StringIO.new
      command = TemplateRenameCommand.new(
        argv: [ "my-product-api" ],
        stdout: stdout,
        stderr: stderr,
        root_path: tmpdir
      )

      command.run

      assert_empty stderr.string
      assert_includes stdout.string, "updated config/application.rb"
      assert_includes stdout.string, "updated docs/openapi.yml"
      assert_includes stdout.string, "updated compose.yml"
      assert_includes stdout.string, "updated config/deploy.yml"
      assert_includes stdout.string, "updated README.md"
      assert_includes stdout.string, "updated app/views/pwa/manifest.json.erb"
      assert_includes stdout.string, "api template rename complete: my-product-api"

      assert_includes File.read(File.join(tmpdir, "config/application.rb")), "module MyProductApi"
      assert_includes File.read(File.join(tmpdir, "docs/openapi.yml")), "title: My Product API"
      assert_includes File.read(File.join(tmpdir, "compose.yml")), "container_name: my-product-api-elasticsearch"
      assert_includes File.read(File.join(tmpdir, "config/deploy.yml")), "my_product_api"
      assert_includes File.read(File.join(tmpdir, "README.md")), "# My Product API"
      manifest = File.read(File.join(tmpdir, "app/views/pwa/manifest.json.erb"))
      assert_includes manifest, '"name": "MyProductApi"'
      assert_includes manifest, '"description": "MyProductApi."'
    end
  end

  test "rewrites discovered existing module references, not only ApiTemplate" do
    Dir.mktmpdir("api-template-rename-legacy-module") do |tmpdir|
      write_fixture_files(tmpdir, module_name: "LegacySuite", deploy_token: "legacy_suite")

      stdout = StringIO.new
      stderr = StringIO.new
      command = TemplateRenameCommand.new(
        argv: [ "legacy-suite-api", "my-product-api" ],
        stdout: stdout,
        stderr: stderr,
        root_path: tmpdir
      )

      command.run

      assert_includes stderr.string, "WARNING: Subsequent renames are best-effort only and have no guarantees after changes have been made to original template."
      manifest = File.read(File.join(tmpdir, "app/views/pwa/manifest.json.erb"))
      refute_includes manifest, "LegacySuite"
      assert_includes manifest, "MyProductApi"
      assert_includes File.read(File.join(tmpdir, "config/deploy.yml")), "my_product_api"
    end
  end

  test "detects current name from module and prompts before subsequent rename" do
    Dir.mktmpdir("api-template-rename-subsequent-prompt") do |tmpdir|
      write_fixture_files(tmpdir, module_name: "LegacySuite", deploy_token: "legacy_suite")

      stdout = StringIO.new
      stderr = StringIO.new
      command = TemplateRenameCommand.new(
        argv: [ "my-product-api" ],
        stdin: StringIO.new("y\n"), # simulate user confirming subsequent rename
        stdout: stdout,
        stderr: stderr,
        root_path: tmpdir
      )

      command.run

      assert_includes stderr.string, "WARNING: Subsequent renames are best-effort only and have no guarantees after changes have been made to original template."
      assert_includes stderr.string, "WARNING: Detected current app name from module 'LegacySuite': legacy-suite."
      assert_includes stderr.string, "Continue rename from 'legacy-suite' to 'my-product-api'? [y/N]:"
      assert_includes stdout.string, "api template rename complete: my-product-api"
      assert_includes File.read(File.join(tmpdir, "config/deploy.yml")), "my_product_api"
    end
  end

  test "cancels subsequent rename when user declines prompt" do
    Dir.mktmpdir("api-template-rename-subsequent-cancel") do |tmpdir|
      write_fixture_files(tmpdir, module_name: "LegacySuite")

      stdout = StringIO.new
      stderr = StringIO.new
      command = TemplateRenameCommand.new(
        argv: [ "my-product-api" ],
        stdin: StringIO.new("n\n"),
        stdout: stdout,
        stderr: stderr,
        root_path: tmpdir
      )

      error = assert_raises(SystemExit) { command.run }

      assert_equal 1, error.status
      assert_empty stdout.string
      assert_includes stderr.string, "WARNING: Subsequent renames are best-effort only and have no guarantees after changes have been made to original template."
      assert_includes stderr.string, "WARNING: Detected current app name from module 'LegacySuite': legacy-suite."
      assert_includes stderr.string, "Continue rename from 'legacy-suite' to 'my-product-api'? [y/N]:"
      assert_includes stderr.string, "Rename cancelled by user."
      assert_includes stderr.string, "Usage: bin/template_rename <current-app-name-kebab-case> <new-app-name-kebab-case>"
    end
  end

  test "warns on subsequent renames (not first rename from ApiTemplate)" do
    Dir.mktmpdir("api-template-rename-warning") do |tmpdir|
      write_fixture_files(tmpdir, module_name: "LegacySuite", deploy_token: "legacy_suite")

      stdout = StringIO.new
      stderr = StringIO.new
      command = TemplateRenameCommand.new(
        argv: [ "legacy-suite-api", "my-product-api" ],
        stdout: stdout,
        stderr: stderr,
        root_path: tmpdir
      )

      command.run

      assert_includes stderr.string, "WARNING: Subsequent renames are best-effort only and have no guarantees after changes have been made to original template."
    end
  end

  test "warns with manual follow-up guidance when old references remain" do
    Dir.mktmpdir("api-template-rename-remaining-refs") do |tmpdir|
      write_fixture_files(tmpdir)
      FileUtils.mkdir_p(File.join(tmpdir, "docs"))
      File.write(
        File.join(tmpdir, "docs/manual_followup.txt"),
        "Legacy mention: ApiTemplate and api-template still appear here.\n"
      )

      stdout = StringIO.new
      stderr = StringIO.new
      command = TemplateRenameCommand.new(
        argv: [ "my-product-api" ],
        stdout: stdout,
        stderr: stderr,
        root_path: tmpdir
      )

      command.run

      assert_includes stderr.string, "WARNING: Found remaining references to previous app names."
      assert_includes stderr.string, "WARNING: Update these references manually, use ai to update references, or run 'git restore .' to undo all local changes."
      assert_includes stderr.string, "WARNING: docs/manual_followup.txt"
    end
  end

  test "exits with usage when app name is missing" do
    stdout = StringIO.new
    stderr = StringIO.new
    command = TemplateRenameCommand.new(argv: [], stdout: stdout, stderr: stderr)

    error = assert_raises(SystemExit) { command.run }

    assert_equal 1, error.status
    assert_empty stdout.string
    assert_includes stderr.string, "Expected one or two app names."
    assert_includes stderr.string, "Usage: bin/template_rename <new-app-name-kebab-case>"
    assert_includes stderr.string, "or: bin/template_rename <original-app-name-kebab-case> <new-app-name-kebab-case>"
  end

  test "exits with usage when app name is invalid" do
    stdout = StringIO.new
    stderr = StringIO.new
    command = TemplateRenameCommand.new(argv: [ "MyProductApi" ], stdout: stdout, stderr: stderr)

    error = assert_raises(SystemExit) { command.run }

    assert_equal 1, error.status
    assert_empty stdout.string
    assert_includes stderr.string, "Invalid app name 'MyProductApi'. Expected kebab-case."
    assert_includes stderr.string, "Usage: bin/template_rename <new-app-name-kebab-case>"
    assert_includes stderr.string, "or: bin/template_rename <original-app-name-kebab-case> <new-app-name-kebab-case>"
  end

  test "abort_with_usage prints usage and exits" do
    command, _stdout, stderr = build_command

    error = assert_raises(SystemExit) { command.send(:abort_with_usage, "bad input") }

    assert_equal 1, error.status
    assert_includes stderr.string, "bad input"
    assert_includes stderr.string, "Usage: bin/template_rename <new-app-name-kebab-case>"
    assert_includes stderr.string, "or: bin/template_rename <original-app-name-kebab-case> <new-app-name-kebab-case>"
  end

  test "abort_with_subsequent_rename_usage prints two-arg usage and exits" do
    command, _stdout, stderr = build_command

    error = assert_raises(SystemExit) do
      command.send(:abort_with_subsequent_rename_usage, "already renamed", current_app_name: "legacy-suite")
    end

    assert_equal 1, error.status
    assert_includes stderr.string, "already renamed"
    assert_includes stderr.string, "Usage: bin/template_rename <current-app-name-kebab-case> <new-app-name-kebab-case>"
    assert_includes stderr.string, "Example: bin/template_rename legacy-suite my-product-api"
    refute_includes stderr.string, "Usage: bin/template_rename <new-app-name-kebab-case>"
  end

  test "warn_message prefixes warning" do
    command, _stdout, stderr = build_command

    command.send(:warn_message, "careful")

    assert_equal "WARNING: careful\n", stderr.string
  end

  test "confirm_subsequent_rename accepts yes and rejects default no" do
    yes_command, _stdout, yes_stderr = build_command(stdin: StringIO.new("yes\n"))
    no_command, _stdout2, no_stderr = build_command(stdin: StringIO.new("\n"))

    assert yes_command.send(:confirm_subsequent_rename!, current_app_name: "legacy-suite", new_name: "my-product-api")
    refute no_command.send(:confirm_subsequent_rename!, current_app_name: "legacy-suite", new_name: "my-product-api")
    assert_includes yes_stderr.string, "Continue rename from 'legacy-suite' to 'my-product-api'? [y/N]:"
    assert_includes no_stderr.string, "Continue rename from 'legacy-suite' to 'my-product-api'? [y/N]:"
  end

  test "validate_name allows kebab-case and rejects invalid names" do
    valid_command, _stdout, _stderr = build_command(argv: [ "unused" ])
    invalid_command, _stdout2, invalid_stderr = build_command(argv: [ "unused" ])

    valid_command.send(:validate_name!, "my-product-api")

    error = assert_raises(SystemExit) { invalid_command.send(:validate_name!, "MyProductApi") }
    assert_equal 1, error.status
    assert_includes invalid_stderr.string, "Invalid app name 'MyProductApi'. Expected kebab-case."
  end

  test "token conversion helpers follow rails conventions" do
    command, _stdout, _stderr = build_command

    assert_equal "MyProductApi", command.send(:camelize, "my-product-api")
    assert_equal "My Product", command.send(:titleize, "my-product")
    assert_equal "my_product_api", command.send(:underscore, "MyProductAPI")
    assert_nil command.send(:underscore, nil)
    assert_nil command.send(:underscore, "")
  end

  test "parse_names defaults old name for first-time template rename" do
    command, _stdout, _stderr = build_command(argv: [ "my-product-api" ])

    assert_equal [ "api-template", "my-product-api" ], command.send(:parse_names, "ApiTemplate")
  end

  test "parse_names warns on subsequent rename and module mismatch" do
    command, _stdout, stderr = build_command(argv: [ "legacy-suite-api", "my-product-api" ])

    names = command.send(:parse_names, "LegacySuite")

    assert_equal [ "legacy-suite-api", "my-product-api" ], names
    assert_includes stderr.string, "WARNING: Subsequent renames are best-effort only and have no guarantees after changes have been made to original template."
    assert_includes stderr.string, "Current module 'LegacySuite' does not match provided original 'LegacySuiteApi'."
  end

  test "detect_current_module_name returns module from config/application.rb" do
    Dir.mktmpdir("api-template-detect-module") do |tmpdir|
      write_fixture_files(tmpdir, module_name: "LegacySuite")
      command, _stdout, _stderr = build_command(root_path: tmpdir)

      assert_equal "LegacySuite", command.send(:detect_current_module_name)
    end
  end

  test "detect_current_module_name returns nil when application file missing" do
    Dir.mktmpdir("api-template-detect-module-missing") do |tmpdir|
      command, _stdout, _stderr = build_command(root_path: tmpdir)

      assert_nil command.send(:detect_current_module_name)
    end
  end

  test "rewrite_module_references updates only configured module reference files" do
    Dir.mktmpdir("api-template-rewrite-module-refs") do |tmpdir|
      write_fixture_files(tmpdir, module_name: "LegacySuite")
      FileUtils.mkdir_p(File.join(tmpdir, "app/services"))
      FileUtils.mkdir_p(File.join(tmpdir, "docs"))
      File.write(File.join(tmpdir, "app/services/uses_module.rb"), "LegacySuite::Client.call\n")
      File.write(File.join(tmpdir, "docs/notes.txt"), "LegacySuite should stay in docs\n")

      command, _stdout, _stderr = build_command(root_path: tmpdir)
      command.send(:rewrite_module_references, old_names: [ "LegacySuite" ], new_name: "MyProductApi")

      assert_includes File.read(File.join(tmpdir, "app/services/uses_module.rb")), "MyProductApi::Client"
      assert_includes File.read(File.join(tmpdir, "config/application.rb")), "module LegacySuite"
      assert_includes File.read(File.join(tmpdir, "docs/notes.txt")), "LegacySuite"
    end
  end

  test "module_reference_files returns only matching files in sorted order" do
    Dir.mktmpdir("api-template-module-reference-files") do |tmpdir|
      write_fixture_files(tmpdir)
      FileUtils.mkdir_p(File.join(tmpdir, "lib/sample"))
      FileUtils.mkdir_p(File.join(tmpdir, "test/lib"))
      FileUtils.mkdir_p(File.join(tmpdir, "app/services"))
      FileUtils.mkdir_p(File.join(tmpdir, "docs"))
      File.write(File.join(tmpdir, "lib/sample/tool.rb"), "module Sample; end\n")
      File.write(File.join(tmpdir, "lib/template_rename_command.rb"), "module LegacySuite; end\n")
      File.write(File.join(tmpdir, "test/lib/template_rename_command_test.rb"), "LegacySuite\n")
      File.write(File.join(tmpdir, "app/services/readme.txt"), "ignore\n")
      File.write(File.join(tmpdir, "docs/notes.txt"), "ignore\n")

      command, _stdout, _stderr = build_command(root_path: tmpdir)
      files = command.send(:module_reference_files)

      assert_includes files, "lib/sample/tool.rb"
      refute_includes files, "docs/notes.txt"
      refute_includes files, "app/services/readme.txt"
      refute_includes files, "lib/template_rename_command.rb"
      refute_includes files, "test/lib/template_rename_command_test.rb"
      assert_equal files.sort, files
    end
  end

  test "warn_on_remaining_references reports only non-ignored file matches" do
    Dir.mktmpdir("api-template-remaining-reference-warnings") do |tmpdir|
      write_fixture_files(tmpdir)
      FileUtils.mkdir_p(File.join(tmpdir, "docs"))
      FileUtils.mkdir_p(File.join(tmpdir, "tmp"))
      File.write(File.join(tmpdir, "docs/manual_followup.txt"), "LegacySuite and legacy-suite-api remain\n")
      File.write(File.join(tmpdir, "tmp/ignored.txt"), "LegacySuite\n")

      command, _stdout, stderr = build_command(root_path: tmpdir)
      command.send(:warn_on_remaining_references, old_module_names: [ "LegacySuite" ], old_name: "legacy-suite-api")

      assert_includes stderr.string, "WARNING: Found remaining references to previous app names."
      assert_includes stderr.string, "WARNING: docs/manual_followup.txt"
      refute_includes stderr.string, "tmp/ignored.txt"
    end
  end

  test "remaining_reference_matches excludes ignored directories" do
    Dir.mktmpdir("api-template-remaining-reference-scan") do |tmpdir|
      write_fixture_files(tmpdir)
      FileUtils.mkdir_p(File.join(tmpdir, "docs"))
      FileUtils.mkdir_p(File.join(tmpdir, "log"))
      FileUtils.mkdir_p(File.join(tmpdir, "coverage"))
      FileUtils.mkdir_p(File.join(tmpdir, "lib"))
      FileUtils.mkdir_p(File.join(tmpdir, "test/lib"))
      File.write(File.join(tmpdir, "docs/hit.txt"), "LegacySuite\n")
      File.write(File.join(tmpdir, "log/ignored.log"), "LegacySuite\n")
      File.write(File.join(tmpdir, "coverage/index.html"), "LegacySuite\n")
      File.write(File.join(tmpdir, "lib/template_rename_command.rb"), "LegacySuite\n")
      File.write(File.join(tmpdir, "test/lib/template_rename_command_test.rb"), "LegacySuite\n")

      command, _stdout, _stderr = build_command(root_path: tmpdir)
      matches = command.send(:remaining_reference_matches, [ "LegacySuite" ])

      assert_equal [ "LegacySuite" ], matches["docs/hit.txt"]
      refute_includes matches.keys, "log/ignored.log"
      refute_includes matches.keys, "coverage/index.html"
      refute_includes matches.keys, "lib/template_rename_command.rb"
      refute_includes matches.keys, "test/lib/template_rename_command_test.rb"
    end
  end

  test "skip_reference_scan_path identifies ignored roots" do
    command, _stdout, _stderr = build_command

    assert command.send(:skip_reference_scan_path?, "log/development.log")
    assert command.send(:skip_reference_scan_path?, ".git/config")
    assert command.send(:skip_reference_scan_path?, "coverage/index.html")
    assert command.send(:skip_reference_scan_path?, "tmp/cache.bin")
    assert command.send(:skip_reference_scan_path?, "storage/blob.bin")
    assert command.send(:skip_reference_scan_path?, "lib/template_rename_command.rb")
    assert command.send(:skip_reference_scan_path?, "test/lib/template_rename_command_test.rb")
    refute command.send(:skip_reference_scan_path?, "docs/notes.txt")
  end

  test "rewrite_file updates changed content and logs path" do
    Dir.mktmpdir("api-template-rewrite-file-changed") do |tmpdir|
      write_fixture_files(tmpdir)
      command, stdout, _stderr = build_command(root_path: tmpdir)

      command.send(:rewrite_file, "README.md") { |content| content.sub("API Template", "Renamed API") }

      assert_includes File.read(File.join(tmpdir, "README.md")), "# Renamed API"
      assert_includes stdout.string, "updated README.md"
    end
  end

  test "rewrite_file does not write when unchanged or missing" do
    Dir.mktmpdir("api-template-rewrite-file-unchanged") do |tmpdir|
      write_fixture_files(tmpdir)
      command, stdout, _stderr = build_command(root_path: tmpdir)

      command.send(:rewrite_file, "README.md") { |content| content }
      command.send(:rewrite_file, "missing.txt") { |content| content + "x" }

      assert_empty stdout.string
    end
  end

  private

  def build_command(argv: [], stdin: StringIO.new, root_path: Dir.pwd)
    stdout = StringIO.new
    stderr = StringIO.new
    command = TemplateRenameCommand.new(argv: argv, stdin: stdin, stdout: stdout, stderr: stderr, root_path: root_path)
    [ command, stdout, stderr ]
  end

  # Creates a minimal fake api template layout used by rename command tests.
  def write_fixture_files(tmpdir, module_name: "ApiTemplate", deploy_token: "api_template")
    FileUtils.mkdir_p(File.join(tmpdir, "config"))
    FileUtils.mkdir_p(File.join(tmpdir, "docs"))
    FileUtils.mkdir_p(File.join(tmpdir, "app/views/pwa"))

    File.write(
      File.join(tmpdir, "config/application.rb"),
      <<~RUBY
        module #{module_name}
        end
      RUBY
    )

    File.write(
      File.join(tmpdir, "docs/openapi.yml"),
      <<~YAML
        info:
          title: API Template API
      YAML
    )

    File.write(
      File.join(tmpdir, "compose.yml"),
      <<~YAML
        services:
          elasticsearch:
            container_name: api-template-elasticsearch
      YAML
    )

    File.write(
      File.join(tmpdir, "config/deploy.yml"),
      <<~YAML
        service: #{deploy_token}
        image: myorg/#{deploy_token}
      YAML
    )

    File.write(
      File.join(tmpdir, "README.md"),
      <<~MARKDOWN
        # API Template

        Internal API service.
      MARKDOWN
    )

    File.write(
      File.join(tmpdir, "app/views/pwa/manifest.json.erb"),
      <<~JSON
        {
          "name": "#{module_name}",
          "description": "#{module_name}."
        }
      JSON
    )
  end
end
