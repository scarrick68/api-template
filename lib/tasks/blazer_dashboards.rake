namespace :blazer do
  desc "Install default Blazer dashboards"
  task install_dashboards: :environment do
    require Rails.root.join("lib/blazer_dashboards/api_observability")

    dashboard_config = BlazerDashboards::ApiObservability

    dashboard = Blazer::Dashboard.find_or_create_by!(
      name: dashboard_config.fetch(:name)
    )

    dashboard_config.fetch(:queries).each_with_index do |query_config, index|
      query = Blazer::Query.find_or_initialize_by(
        name: query_config.fetch(:name)
      )

      query.statement = query_config.fetch(:statement).strip
      query.data_source = "main" if query.respond_to?(:data_source=)
      query.save!

      dashboard_query = Blazer::DashboardQuery.find_or_initialize_by(
        dashboard: dashboard,
        query: query
      )

      dashboard_query.position = index + 1 if dashboard_query.respond_to?(:position=)
      dashboard_query.save!
    end

    puts "Installed Blazer dashboard: #{dashboard.name}"
  end
end
