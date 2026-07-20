# frozen_string_literal: true

# bundle exec rails local_ci:prod_local_smoke
namespace :local_ci do
  desc "Smoke test local production boot by running bin/prod-local and checking /up"
  task prod_local_smoke: :environment do
    LocalCi::ProdLocalSmokeTest.run!
  end
end
