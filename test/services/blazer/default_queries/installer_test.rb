require "test_helper"

class BlazerDefaultQueriesInstallerTest < ActiveSupport::TestCase
  test "installs valid definitions and creates bookkeeping records" do
    definition = build_definition

    result = nil

    assert_difference("Blazer::Query.count", 1) do
      assert_difference("BlazerQueryInstallation.count", 1) do
        result = installer_with([ definition ]).call
      end
    end

    query = Blazer::Query.last
    installation = BlazerQueryInstallation.last

    assert_equal [ definition ], result.installed
    assert_empty result.skipped

    assert_equal "Users Overview v1", query.name
    assert_equal "main", query.data_source
    assert_equal definition.sql_statement, query.statement

    assert_equal "users_overview", installation.query_key
    assert_equal 1, installation.query_version
    assert_equal query, installation.blazer_query
    assert installation.installed_at.present?
  end

  test "skips a definition that was already installed" do
    definition = build_definition

    create_installed_record_for(definition)

    result = nil

    assert_no_difference("Blazer::Query.count") do
      assert_no_difference("BlazerQueryInstallation.count") do
        result = installer_with([ definition ]).call
      end
    end

    assert_empty result.installed
    assert_equal [ definition ], result.skipped
  end

  test "validates all definitions before writing any records" do
    valid_definition = build_definition
    invalid_definition = build_definition(key: "invalid_query", sql_statement: " ")

    error = nil

    assert_no_changes -> { Blazer::Query.count } do
      assert_no_changes -> { BlazerQueryInstallation.count } do
        error = assert_raises(Blazer::DefaultQueries::Installer::Error) do
          installer_with([ valid_definition, invalid_definition ]).call
        end
      end
    end

    assert_equal "Default query 'Users Overview v1' has an invalid sql_statement.", error.message
  end

  test "rejects definitions that are not Definition objects" do
    error = assert_raises(Blazer::DefaultQueries::Installer::Error) do
      installer_with([ { key: "users_overview", version: 1 } ]).call
    end

    assert_match "must be a Blazer::DefaultQueries::Definition", error.message
  end

  test "rejects a non-array definitions collection" do
    error = assert_raises(Blazer::DefaultQueries::Installer::Error) do
      installer_with(build_definition).call
    end

    assert_equal "Default query definitions must be an array.", error.message
  end

  test "rejects blank required string fields" do
    %i[key name data_source sql_statement].each do |field|
      definition = build_definition(field => " ")

      error = assert_raises(Blazer::DefaultQueries::Installer::Error) do
        installer_with([ definition ]).call
      end

      assert_match "invalid #{field}", error.message
    end
  end

  test "rejects invalid versions" do
    [ nil, 0, -1, "1" ].each do |version|
      definition = build_definition(version: version)

      error = assert_raises(Blazer::DefaultQueries::Installer::Error) do
        installer_with([ definition ]).call
      end

      assert_match "must have a positive integer version", error.message
    end
  end

  test "allows same query key with different versions" do
    definitions = [
      build_definition(version: 1),
      build_definition(version: 2)
    ]

    result = nil

    assert_difference("Blazer::Query.count", 2) do
      assert_difference("BlazerQueryInstallation.count", 2) do
        result = installer_with(definitions).call
      end
    end

    assert_equal definitions, result.installed
    assert_empty result.skipped
  end

  test "rejects duplicate query key and version pairs before writing records" do
    definitions = [
      build_definition(version: 1),
      build_definition(version: 1)
    ]

    error = nil

    assert_no_changes -> { Blazer::Query.count } do
      assert_no_changes -> { BlazerQueryInstallation.count } do
        error = assert_raises(Blazer::DefaultQueries::Installer::Error) do
          installer_with(definitions).call
        end
      end
    end

    assert_includes error.message, "Duplicate default query key+version pairs: users_overview@v1."
  end

  test "installs missing definitions while skipping installed definitions" do
    installed_definition = build_definition
    new_definition = build_definition(
      key: "recent_signups",
      name: "Recent Signups"
    )

    create_installed_record_for(installed_definition)

    result = nil

    assert_difference("Blazer::Query.count", 1) do
      assert_difference("BlazerQueryInstallation.count", 1) do
        result = installer_with([ installed_definition, new_definition ]).call
      end
    end

    assert_equal [ new_definition ], result.installed
    assert_equal [ installed_definition ], result.skipped
  end

  test "does not overwrite an operator-edited query" do
    definition = build_definition

    installer_with([ definition ]).call

    query = Blazer::Query.last
    query.update!(
      name: "Customized Users Report",
      statement: "SELECT id FROM users"
    )

    installer_with([ definition ]).call

    query.reload

    assert_equal "Customized Users Report", query.name
    assert_equal "SELECT id FROM users", query.statement
  end

  test "does not recreate an operator-deleted query" do
    definition = build_definition

    installer_with([ definition ]).call

    Blazer::Query.last.destroy!

    assert_no_difference("Blazer::Query.count") do
      result = installer_with([ definition ]).call

      assert_empty result.installed
      assert_equal [ definition ], result.skipped
    end
  end

  test "rolls back the blazer query when bookkeeping fails" do
    definition = build_definition

    BlazerQueryInstallation.any_instance.stubs(:save!).raises(ActiveRecord::RecordInvalid)

    assert_no_changes -> { Blazer::Query.count } do
      assert_no_changes -> { BlazerQueryInstallation.count } do
        assert_raises(ActiveRecord::RecordInvalid) do
          installer_with([ definition ]).call
        end
      end
    end
  end

  private

  def build_definition(
    key: "users_overview",
    version: 1,
    name: "Users Overview",
    dashboard_group: "API Observability",
    data_source: "main",
    sql_statement: "SELECT * FROM users"
  )
    Blazer::DefaultQueries::Definition.new(
      key: key,
      version: version,
      name: name,
      dashboard_group: dashboard_group,
      data_source: data_source,
      sql_statement: sql_statement
    )
  end

  def installer_with(definitions)
    installer = Blazer::DefaultQueries::Installer.new
    installer.stubs(:query_definitions).returns(definitions)
    installer
  end

  def create_installed_record_for(definition)
    query = create(
      :blazer_query,
      name: "#{definition.name} v#{definition.version}",
      data_source: definition.data_source,
      statement: definition.sql_statement
    )

    create(
      :blazer_query_installation,
      query_key: definition.key,
      query_version: definition.version,
      blazer_query: query
    )
  end
end
