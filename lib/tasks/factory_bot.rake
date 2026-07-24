# frozen_string_literal: true

namespace :factory_bot do
  desc "Lint factories without persisting records"
  task lint: :environment do
    ActiveRecord::Base.transaction do
      FactoryBot.lint(traits: true)
      raise ActiveRecord::Rollback
    end
  end
end
