require "test_helper"

module DataImports
  class RegistryTest < ActiveSupport::TestCase
    test "raises descriptive error when importer is not registered" do
      error = assert_raises(KeyError) do
        Registry.fetch("missing_schema", "v1")
      end

      assert_includes error.message, "No importer registered"
      assert_includes error.message, "missing_schema"
    end
  end
end
