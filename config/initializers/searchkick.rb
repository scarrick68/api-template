Searchkick.client = OpenSearch::Client.new(
  url: ENV.fetch("OPENSEARCH_URL", "http://localhost:9200")
)

Ethon.logger = Logger.new(nil)
