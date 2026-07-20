class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("DEFAULT_EMAIL_FROM", "no-reply@example.test")
  layout "mailer"
end
