# Admin action for creating a DataArtifact from an uploaded file in Avo.
class Avo::Actions::DataArtifacts::UploadArtifact < Avo::BaseAction
  self.name = "Data Artifacts/Upload Artifact"
  self.standalone = true
  self.message = "Upload one artifact file and create a DataArtifact record."
  # self.visible = -> do
  #   true
  # end

  def fields
    field :artifact_file, as: :file, required: true
    field :schema_name, as: :text, required: true
    field :schema_version, as: :text
    field :source, as: :text
  end

  def handle(query:, fields:, current_user:, resource:, **args)
    file = fields[:artifact_file]

    unless file
      fail "Please select a file to upload."
    end

    # Persist a first-class artifact row before attaching bytes.
    artifact = DataArtifact.create!(
      artifact_id: build_artifact_id(file),
      schema_name: fields[:schema_name],
      schema_version: fields[:schema_version].presence,
      source: fields[:source].presence || "admin_upload",
      status: :pending
    )

    # Store file-level facts directly on DataArtifact for quick operator visibility.
    artifact.file.attach(file)
    artifact.reload
    update_file_metadata!(artifact)

    # JSON uploads may be manifest files, so attempt schema validation.
    maybe_validate_manifest!(artifact)

    succeed "Uploaded artifact ##{artifact.id} (#{artifact.artifact_id})."
  rescue StandardError => e
    fail "Upload failed: #{e.message}"
  end

  private

  def build_artifact_id(file)
    # Keep IDs deterministic enough for humans while avoiding collisions.
    base = file.original_filename.to_s.sub(/\.[^.]+\z/, "").parameterize(separator: "_")
    timestamp = Time.current.utc.strftime("%Y%m%d%H%M%S")

    [ base.presence || "artifact", timestamp ].join("-")
  end

  def update_file_metadata!(artifact)
    blob = artifact.file.blob
    metadata = (artifact.metadata || {}).dup
    metadata["uploaded_via"] = "avo"

    artifact.update!(
      byte_size: blob.byte_size,
      checksum: blob.checksum,
      content_type: blob.content_type,
      metadata: metadata
    )
  end

  def maybe_validate_manifest!(artifact)
    return unless artifact.file.filename.extension.to_s.downcase == "json"

    DataImports::ManifestReader.call(artifact:)
  end
end
