Searchkick.client = Elasticsearch::Client.new(
  url: ENV.fetch("ELASTICSEARCH_URL", "http://localhost:9200")
)

Ethon.logger = Logger.new(nil)
