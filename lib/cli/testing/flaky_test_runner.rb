# frozen_string_literal: true

require "optparse"

module Cli
  module Testing
    # Runs a single Rails test filter repeatedly to surface flaky behavior.
    class FlakyTestRunner
      DEFAULT_FILE = "test/integration/user_sessions_test.rb"
      DEFAULT_FILTER = "/admin can sign in with valid credentials/"
      DEFAULT_RUNS = 15

      def initialize(argv, stdout: $stdout, stderr: $stderr)
        @argv = argv.dup
        @stdout = stdout
        @stderr = stderr
      end

      def call
        options = parse_options
        return 0 if options[:help]

        failures = 0

        1.upto(options[:runs]) do |index|
          stdout.puts
          stdout.puts "=== Run #{index}/#{options[:runs]} ==="

          ok = run_once(file: options[:file], filter: options[:filter])
          if ok
            stdout.puts "Run #{index}: PASS"
          else
            stdout.puts "Run #{index}: FAIL"
            failures += 1
          end
        end

        stdout.puts
        stdout.puts "Completed #{options[:runs]} runs. Fails: #{failures}"

        failures.zero? ? 0 : 1
      end

      private

      attr_reader :argv, :stdout, :stderr

      def parse_options
        options = {
          file: DEFAULT_FILE,
          filter: DEFAULT_FILTER,
          runs: DEFAULT_RUNS,
          help: false
        }

        parser = OptionParser.new do |opts|
          opts.banner = "Usage: bin/test-flaky-admin-sign-in [options]"

          opts.on("--runs N", Integer, "Number of runs (default: #{DEFAULT_RUNS})") do |value|
            options[:runs] = value
          end

          opts.on("--file PATH", "Test file path (default: #{DEFAULT_FILE})") do |value|
            options[:file] = value
          end

          opts.on("--filter PATTERN", "Minitest include pattern (default: #{DEFAULT_FILTER})") do |value|
            options[:filter] = value
          end

          opts.on("-h", "--help", "Show usage") do
            options[:help] = true
          end
        end

        parser.parse!(argv)

        if options[:help]
          stdout.puts parser
          stdout.puts
          stdout.puts "Examples:"
          stdout.puts "  bin/test-flaky-admin-sign-in"
          stdout.puts "  bin/test-flaky-admin-sign-in --runs 30"
          stdout.puts "  bin/test-flaky-admin-sign-in --filter '/admin can sign in/'"
        end

        if options[:runs] <= 0
          raise OptionParser::InvalidArgument, "--runs must be greater than 0"
        end

        options
      rescue OptionParser::ParseError => e
        stderr.puts "Argument error: #{e.message}"
        stderr.puts "Run with --help for usage."
        exit 2
      end

      def run_once(file:, filter:)
        command = [ "bundle", "exec", "rails", "test", file, "-i", filter ]
        env = {
          "COVERAGE" => "false",
          "SKOOMA_COVERAGE_REPORT" => "false"
        }

        system(env, *command)
      end
    end
  end
end
