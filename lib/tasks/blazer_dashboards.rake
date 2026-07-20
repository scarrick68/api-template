namespace :blazer do
  desc "Install default Blazer dashboards"
  task install_dashboards: :environment do
    grouped_definitions = Blazer::DefaultQueries::Definitions.all.group_by(&:dashboard_group)

    grouped_definitions.each do |dashboard_group, definitions|
      dashboard = Blazer::Dashboard.find_or_create_by!(name: dashboard_group)

      definitions.each_with_index do |definition, index|
        query = find_or_build_query(definition)
        query.statement = definition.sql_statement.strip
        query.data_source = definition.data_source if query.respond_to?(:data_source=)
        query.save!

        dashboard_query = Blazer::DashboardQuery.find_or_initialize_by(
          dashboard: dashboard,
          query: query
        )

        dashboard_query.position = index + 1 if dashboard_query.respond_to?(:position=)
        dashboard_query.save!
      end
    end

    puts "Installed Blazer dashboards"
  end

  def find_or_build_query(definition)
    target_name = "#{definition.name} v#{definition.version}"
    query = Blazer::Query.find_by(name: target_name)
    return query if query

    legacy_query = Blazer::Query.find_by(name: definition.name)
    if legacy_query
      legacy_query.name = target_name
      return legacy_query
    end

    Blazer::Query.new(name: target_name)
  end
end
