class RemoveMetricsDefaultsForMetricTypeAndValue < ActiveRecord::Migration[8.1]
  def up
    change_column_default :metrics, :metric_type, from: "counter", to: nil
    change_column_default :metrics, :value, from: 1, to: nil
  end

  def down
    change_column_default :metrics, :metric_type, from: nil, to: "counter"
    change_column_default :metrics, :value, from: nil, to: 1
  end
end
