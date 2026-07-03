# frozen_string_literal: true

namespace :data_imports do
  desc "Create and enqueue a DataImportRun for a DataArtifact"
  task :start_run, [ :data_artifact_id, :mode ] => :environment do |_task, args|
    args.with_defaults(mode: "import")

    run = Commands::Tasks::DataImports::StartRunCommand.call(
      data_artifact_id: args[:data_artifact_id],
      mode: args[:mode]
    )

    puts "Created DataImportRun ##{run.id}"
    puts "  data_artifact_id: #{run.data_artifact_id}"
    puts "  schema_name: #{run.schema_name}"
    puts "  schema_version: #{run.schema_version}"
    puts "  mode: #{run.mode}"
    puts "  status: #{run.status}"
    puts "  attempt: #{run.options.to_h['attempt']}"
  end
end
