class CreateBlazerQueryInstallations < ActiveRecord::Migration[8.1]
  def change
    create_table :blazer_query_installations do |t|
      t.string :query_key, null: false
      t.integer :query_version, null: false
      t.bigint :blazer_query_id
      t.datetime :installed_at, null: false

      t.timestamps
    end

    add_index :blazer_query_installations, [ :query_key, :query_version ], unique: true

    add_foreign_key :blazer_query_installations,
      :blazer_queries,
      column: :blazer_query_id,
      on_delete: :nullify,
      validate: false
  end
end
