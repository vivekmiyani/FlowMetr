class AddPayloadToMeasurementLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :measurement_logs, :payload, :jsonb
  end
end
