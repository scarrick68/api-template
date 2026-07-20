require Rails.root.join("lib/cli/colors")

namespace :email do
  def print_email_doctor_output(result)
    puts Cli::Colors.heading("Email delivery")
    puts
    puts "  Delivery method: #{result.delivery_method || "none"}"
    puts "  Deliveries enabled: #{result.perform_deliveries ? "yes" : "no"}"
    puts "  Delivery errors raised: #{result.raise_delivery_errors ? "yes" : "no"}"
    puts "  Mailer URL host: #{result.mailer_host.empty? ? "(missing)" : result.mailer_host}"

    if result.issues.empty?
      puts
      puts "  Status: #{Cli::Colors.ok}"
      return
    end

    puts
    result.issues.each do |issue|
      label = issue.level == :failure ? Cli::Colors.fail : Cli::Colors.warn
      puts "  #{label}: #{issue.message}"
    end

    puts
    if result.delivery_method == :test
      puts "  Mail-triggering operations will complete, but messages will not be sent."
      puts "  Users may be confirmed manually through Avo admin dashboard."
    end
  end

  desc "Inspect resolved Action Mailer configuration (set LAUNCH_READY=true for strict checks)"
  task doctor: :environment do
    launch_ready = !!ActiveModel::Type::Boolean.new.cast(ENV["LAUNCH_READY"])
    result = Email::DoctorCheck.new(launch_ready: launch_ready).call

    print_email_doctor_output(result)

    if result.failed?
      abort "\nEmail doctor failed launch-readiness checks."
    end
  end

  namespace :doctor do
    desc "Inspect resolved Action Mailer configuration with launch-readiness failures"
    task launch_ready: :environment do
      result = Email::DoctorCheck.new(launch_ready: true).call

      print_email_doctor_output(result)

      abort "\nEmail doctor failed launch-readiness checks." if result.failed?
    end
  end
end
