class Avo::Actions::DataArtifacts::DryRunImport < Avo::BaseAction
  self.name = "Data Artifacts/Dry Run Import"
  self.message = "Create dry-run import runs for selected artifacts and enqueue DataImportJob."

  def handle(query:, **)
    enqueued = 0

    query.each do |artifact|
      next unless artifact.ready_for_import?

      DataImports::StartRun.call(data_artifact: artifact, mode: "dry_run")
      enqueued += 1
    end

    if enqueued.zero?
      fail "No import runs were created. Ensure selected artifacts include schema_name and schema_version."
    else
      succeed "Created and enqueued #{enqueued} dry-run import run(s)."
    end
  rescue StandardError => e
    fail "Dry-run import failed: #{e.message}"
  end
end
