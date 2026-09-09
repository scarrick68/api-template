class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :age, :integer
    add_column :users, :height_ft, :integer
    add_column :users, :height_inches, :integer
    add_column :users, :weight_lbs, :decimal, precision: 7, scale: 2
    add_column :users, :activity_level, :integer
    add_column :users, :goal, :string
    add_column :users, :time_zone, :string
  end
end
