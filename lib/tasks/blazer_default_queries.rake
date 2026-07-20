namespace :blazer do
  namespace :default_queries do
    desc "Install bundled default Blazer queries"
    task install: :environment do
      puts "Installing default Blazer queries..."

      result = Blazer::DefaultQueries::Installer.new.call

      result.installed.each do |definition|
        puts "  installed: #{definition.name} v#{definition.version}"
      end

      result.skipped.each do |definition|
        puts "  skipped: #{definition.name} v#{definition.version}"
      end

      puts "Installed #{result.installed.size} queries."
      puts "Skipped #{result.skipped.size} queries."
    end
  end
end
