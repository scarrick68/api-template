class ValidateBlazerQueryInstallationsForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :blazer_query_installations, :blazer_queries
  end
end
