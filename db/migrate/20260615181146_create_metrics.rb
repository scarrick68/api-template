class CreateMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :metrics do |t|
      t.datetime :occurred_at, null: false

      t.string :name, null: false

      t.string :request_id
      # This creates an index
      t.references :user, foreign_key: false
      t.string :visitor_token

      t.jsonb :properties, null: false, default: {}

      t.timestamps
    end

    add_index :metrics, :occurred_at
    add_index :metrics, :name
    add_index :metrics, [ :name, :occurred_at ]
    add_index :metrics, :request_id
  end
end
