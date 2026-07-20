require "test_helper"

class BlazerDefaultQueriesDefinitionsSqlTest < ActiveSupport::TestCase
  test "all default query sql statements are valid" do
    definitions = Blazer::DefaultQueries::Definitions.all

    assert definitions.any?, "expected at least one default query definition"

    definitions.each do |definition|
      sql = definition.sql_statement.to_s.strip
      assert sql.present?, "expected sql_statement to be present for #{definition.key}"

      begin
        ActiveRecord::Base.connection.execute("EXPLAIN #{sql}")
      rescue ActiveRecord::StatementInvalid => e
        flunk("invalid SQL for #{definition.key} v#{definition.version} (#{definition.name}): #{e.message}")
      end
    end
  end
end
