class AddMetricDimensionsAndValues < ActiveRecord::Migration[8.1]
  def change
    add_column :metrics, :metric_type, :string, null: false, default: "counter"
    add_column :metrics, :value, :decimal, precision: 20, scale: 6, null: false, default: 1
    add_column :metrics, :labels, :jsonb, null: false, default: {}

    add_index :metrics, :labels, using: :gin
  end
end
