# frozen_string_literal: true

Rails.application.configure do
  recurring = config_for(:recurring) || {}
  cron_config = recurring["cron"] || recurring[:cron] || {}

  config.good_job.enable_cron = true
  config.good_job.cron = cron_config.deep_symbolize_keys
end
