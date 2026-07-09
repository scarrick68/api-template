# script/support/local_ci/services.rb

require "net/http"
require "socket"
require "timeout"
require "uri"

module LocalCi
  module Services
    module_function

    def wait_for_opensearch!(
      url: ENV.fetch("OPENSEARCH_URL", "http://localhost:9200"),
      timeout: 120
    )
      wait_for_http!(
        "OpenSearch",
        "#{url}/_cluster/health?wait_for_status=yellow&timeout=1s",
        timeout:
      )
    end

    def wait_for_postgres!(
      host: ENV.fetch("POSTGRES_HOST", "localhost"),
      port: Integer(ENV.fetch("POSTGRES_PORT", 5432)),
      timeout: 60
    )
      wait_for_tcp!("Postgres", host:, port:, timeout:)
    end

    def wait_for_http!(name, url, timeout: 60, interval: 2)
      uri = URI(url)
      deadline = Time.now + timeout

      until Time.now >= deadline
        begin
          response = Net::HTTP.get_response(uri)
          return puts "#{name} is ready" if response.is_a?(Net::HTTPSuccess)
        rescue Errno::ECONNREFUSED,
               Errno::ECONNRESET,
               EOFError,
               SocketError,
               Net::ReadTimeout,
               Net::OpenTimeout
        end

        puts "Waiting for #{name}..."
        sleep interval
      end

      abort "#{name} did not become ready within #{timeout} seconds."
    end

    def wait_for_tcp!(name, host:, port:, timeout: 60, interval: 2)
      deadline = Time.now + timeout

      until Time.now >= deadline
        begin
          Socket.tcp(host, port, connect_timeout: 2) { return puts "#{name} is ready" }
        rescue Errno::ECONNREFUSED,
               Errno::EHOSTUNREACH,
               SocketError,
               Timeout::Error
        end

        puts "Waiting for #{name}..."
        sleep interval
      end

      abort "#{name} did not become ready within #{timeout} seconds."
    end
  end
end
