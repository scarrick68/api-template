class Avo::Resources::DataImportRunResource < Avo::BaseResource
  self.model_class = ::DataImportRun

  def fields
    field :id, as: :id
    field :data_artifact, as: :belongs_to
    field :status, as: :badge
    field :mode, as: :text
    field :records_seen, as: :number
    field :records_imported, as: :number
    field :records_failed, as: :number
    field :error_details, as: :code, name: "errors", language: "json"
    field :started_at, as: :date_time
    field :finished_at, as: :date_time
    field :created_at, as: :date_time
  end
end
