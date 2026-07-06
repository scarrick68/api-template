namespace :searchkick do
  desc "Verify OpenSearch connectivity"
  task health: :environment do
    info = Searchkick.client.info

    puts "✅ OpenSearch is healthy"
    puts "Cluster: #{info.dig('cluster_name')}"
    puts "Version: #{info.dig('version', 'number')}"
  rescue StandardError => e
    warn "❌ OpenSearch health check failed"
    warn "#{e.class}: #{e.message}"
    exit 1
  end
end
