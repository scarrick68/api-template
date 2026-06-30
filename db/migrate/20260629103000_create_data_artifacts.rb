# frozen_string_literal: true

class CreateDataArtifacts < ActiveRecord::Migration[8.1]
  def change
    create_table :data_artifacts do |t|
      t.string :artifact_id, null: false
      t.string :schema_name, null: false
      t.string :schema_version
      t.string :source
      t.string :status, null: false, default: "pending"
      t.jsonb :metadata, null: false, default: {}
      t.string :checksum
      t.bigint :byte_size
      t.string :content_type
      t.bigint :uploaded_by_id

      t.timestamps
    end

    add_index :data_artifacts, :artifact_id, unique: true
    add_index :data_artifacts, :schema_name
    add_index :data_artifacts, :status
    add_index :data_artifacts, :uploaded_by_id
  end
end
