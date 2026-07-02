class Avo::Resources::DataArtifact < Avo::BaseResource
  self.model_class = ::DataArtifact

  def actions
    action Avo::Actions::DataArtifacts::UploadArtifact
    action Avo::Actions::DataArtifacts::DryRunImport
    action Avo::Actions::DataArtifacts::RunImport
  end

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
