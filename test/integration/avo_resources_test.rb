require "test_helper"

class AvoResourcesTest < ApplicationDispatchTest
  setup do
    Avo::Licensing::HQ.any_instance.stubs(:response).returns({})
    sign_in create(:admin), scope: :admin
  end

  test "admin can access data artifacts index and show pages" do
    artifact = DataArtifact.create!(
      artifact_id: "artifact-avo-smoke-1",
      schema_name: "test_schema_name",
      schema_version: "v1"
    )

    get "/avo/resources/data_artifacts"
    assert_response :success

    get "/avo/resources/data_artifacts/#{artifact.id}"
    assert_response :success
  end

  test "admin can access data import runs index and show pages" do
    artifact = DataArtifact.create!(
      artifact_id: "artifact-avo-smoke-2",
      schema_name: "test_schema_name",
      schema_version: "v1"
    )

    run = DataImportRun.create!(
      data_artifact: artifact,
      schema_name: "test_schema_name",
      schema_version: "v1",
      mode: "import",
      status: :pending
    )

    get "/avo/resources/data_import_runs"
    assert_response :success

    get "/avo/resources/data_import_runs/#{run.id}"
    assert_response :success
  end
end
