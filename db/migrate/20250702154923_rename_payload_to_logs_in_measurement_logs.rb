class RenamePayloadToLogsInMeasurementLogs < ActiveRecord::Migration[8.0]
  def change
    rename_column :measurement_logs, :payload, :logs
  end
end

