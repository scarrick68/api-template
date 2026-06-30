# frozen_string_literal: true

class CreateDataImportRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :data_import_runs do |t|
      t.references :data_artifact, null: false, foreign_key: true
      t.string :schema_name, null: false
      t.string :schema_version, null: false
      t.string :status, null: false, default: "pending"
      t.string :mode
      t.jsonb :options, null: false, default: {}
      t.integer :records_seen, null: false, default: 0
      t.integer :records_imported, null: false, default: 0
      t.integer :records_failed, null: false, default: 0
      t.jsonb :error_details, null: false, default: []
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :data_import_runs, :status
    add_index :data_import_runs, %i[schema_name schema_version]
  end
end
