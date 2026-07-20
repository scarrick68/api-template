# frozen_string_literal: true

module Email
  class DoctorCheck
    Issue = Data.define(:level, :message)

    Result = Data.define(
      :launch_ready,
      :delivery_method,
      :perform_deliveries,
      :raise_delivery_errors,
      :mailer_host,
      :issues
    ) do
      def failures
        issues.select { |issue| issue.level == :failure }
      end

      def warnings
        issues.select { |issue| issue.level == :warning }
      end

      def failed?
        failures.any?
      end
    end

    def initialize(launch_ready: false)
      @launch_ready = launch_ready
    end

    def call
      issues = []
      delivery_method = normalize_delivery_method(mailer_config.delivery_method)
      perform_deliveries = !!mailer_config.perform_deliveries
      raise_delivery_errors = !!mailer_config.raise_delivery_errors
      mailer_host = extract_host(mailer_config.default_url_options)

      if delivery_method == :test
        issues << Issue.new(
          level_for_readiness,
          "Action Mailer is using test delivery mode. External email delivery is disabled."
        )
      end

      unless perform_deliveries
        issues << Issue.new(
          level_for_readiness,
          "Action Mailer deliveries are disabled."
        )
      end

      if delivery_method == :smtp
        smtp_address = extract_smtp_address(mailer_config.smtp_settings)

        if smtp_address.empty? || smtp_address == "localhost"
          issues << Issue.new(
            level_for_readiness,
            "SMTP delivery is configured with a blank or localhost host."
          )
        end
      end

      if mailer_host.empty?
        issues << Issue.new(
          level_for_readiness,
          "Action Mailer default_url_options host is missing."
        )
      end

      if default_sender.to_s.strip.empty?
        issues << Issue.new(
          level_for_readiness,
          "Application mailer default sender is missing."
        )
      end

      Result.new(
        launch_ready: launch_ready,
        delivery_method: delivery_method,
        perform_deliveries: perform_deliveries,
        raise_delivery_errors: raise_delivery_errors,
        mailer_host: mailer_host,
        issues: issues
      )
    end

    private

    attr_reader :launch_ready

    def mailer_config
      @mailer_config ||= Rails.application.config.action_mailer
    end

    def default_sender
      @default_sender ||= ApplicationMailer.default_params[:from]
    end

    def level_for_readiness
      launch_ready ? :failure : :warning
    end

    def normalize_delivery_method(value)
      value&.to_sym
    end

    def extract_host(default_url_options)
      return "" unless default_url_options.respond_to?(:[])

      default_url_options[:host].to_s.strip
    end

    def extract_smtp_address(smtp_settings)
      return "" unless smtp_settings.respond_to?(:[])

      smtp_settings[:address].to_s.strip.downcase
    end
  end
end
