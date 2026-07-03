# frozen_string_literal: true

# Local/dev task wrappers for DataArtifact upload flows.
namespace :data_artifacts do
  desc "Upload a local file into DataArtifact + ActiveStorage"
  task :upload_local, [ :file_path, :schema_name, :schema_version, :source ] => :environment do |_task, args|
    args.with_defaults(source: "rake_upload_local")

    artifact = Commands::Tasks::DataArtifacts::UploadLocalCommand.call(
      file_path: args[:file_path].to_s,
      schema_name: args[:schema_name].to_s,
      schema_version: args[:schema_version].presence,
      source: args[:source].presence || "rake_upload_local"
    )

    puts "Created DataArtifact ##{artifact.id}"
    puts "  artifact_id: #{artifact.artifact_id}"
    puts "  schema_name: #{artifact.schema_name}"
    puts "  schema_version: #{artifact.schema_version || "(none)"}"
    puts "  source: #{artifact.source}"
    puts "  status: #{artifact.status}"
    puts "  byte_size: #{artifact.byte_size}"
    puts "  checksum: #{artifact.checksum}"
  end
end
