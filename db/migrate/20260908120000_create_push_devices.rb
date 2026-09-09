class CreatePushDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :push_devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :push_token, null: false
      t.string :platform, null: false
      t.string :app_version
      t.string :build_version
      t.boolean :active, null: false, default: true
      t.datetime :last_registered_at, null: false

      t.timestamps
    end

    add_index :push_devices, :push_token, unique: true
    add_index :push_devices, [ :user_id, :active ]
  end
end
