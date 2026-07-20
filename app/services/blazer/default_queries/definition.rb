module Blazer
  module DefaultQueries
    Definition = Data.define(
      :key,
      :version,
      :name,
      :dashboard_group,
      :data_source,       # data_source, like main db, other db, etc. This is the key in config/blazer.yml
      :sql_statement
    )
  end
end
