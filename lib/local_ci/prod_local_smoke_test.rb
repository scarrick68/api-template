# frozen_string_literal: true

require "net/http"
require "uri"
require "timeout"
require "fileutils"
require_relative "../cli/colors"

module LocalCi
  # Local CI smoke test that boots `bin/prod-local` and asserts `/up` becomes healthy.
  # This is intentionally lightweight and can run in non-blocking mode from CI runners.
  class ProdLocalSmokeTest
    class << self
      DEFAULT_PORT = "5001"
      DEFAULT_TIMEOUT_SECONDS = 90

      def run!
        port = ENV.fetch("PORT", DEFAULT_PORT)
        timeout_seconds = Integer(ENV.fetch("PROD_LOCAL_SMOKE_TIMEOUT", DEFAULT_TIMEOUT_SECONDS))
        up_url = URI("http://127.0.0.1:#{port}/up")

        log_path = File.expand_path("../../tmp/prod-local-smoke.log", __dir__)
        FileUtils.mkdir_p(File.dirname(log_path))
        log = File.open(log_path, "w")

        env = {
          "PORT" => port
        }

        pid = Process.spawn(env, "bin/prod-local", out: log, err: log)

        begin
          wait_for_up!(up_url, pid: pid, timeout_seconds: timeout_seconds)
          puts "#{cli_colors.ok} prod-local smoke check passed at #{up_url}"
        rescue StandardError => e
          warn "#{cli_colors.fail('ERROR', io: $stderr)} #{e.message}"
          warn "#{cli_colors.warn(io: $stderr)} See log: #{log_path}"
          raise SystemExit, 1
        ensure
          terminate_process(pid)
          log.close
        end
      end

      def wait_for_up!(uri, pid:, timeout_seconds:)
        deadline = Time.now + timeout_seconds

        until Time.now >= deadline
          if (status = Process.waitpid(pid, Process::WNOHANG))
            raise StandardError,
                  "prod-local process exited before /up became ready (pid=#{status}, exit=#{$CHILD_STATUS&.exitstatus || 'unknown'})"
          end

          begin
            response = Net::HTTP.get_response(uri)
            return if response.is_a?(Net::HTTPSuccess)
          rescue Errno::ECONNREFUSED,
                 Errno::ECONNRESET,
                 EOFError,
                 SocketError,
                 Net::ReadTimeout,
                 Net::OpenTimeout
          end

          sleep 1
        end

        raise StandardError, "prod-local smoke check failed: #{uri} did not become ready within #{timeout_seconds} seconds"
      end

      def terminate_process(pid)
        Process.kill("TERM", pid)
        Timeout.timeout(10) { Process.wait(pid) }
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      rescue Timeout::Error
        Process.kill("KILL", pid) rescue nil
      end

      def cli_colors
        Cli::Colors
      end
    end
  end
end
