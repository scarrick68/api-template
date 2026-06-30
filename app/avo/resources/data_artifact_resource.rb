class Avo::Resources::DataArtifactResource < Avo::BaseResource
  def fields
    field :id, as: :id
    field :artifact_id, as: :text
    field :schema_name, as: :text
    field :schema_version, as: :text
    field :status, as: :badge
    field :source, as: :text
    field :file, as: :file
    field :checksum, as: :text
    field :byte_size, as: :number
    field :metadata, as: :code, language: "json"
    field :created_at, as: :date_time

    field :data_import_runs, as: :has_many
  end
end
