class RenameIdentifierToNodeIdInMeasurementPoints < ActiveRecord::Migration[8.0]
  def change
    rename_column :measurement_points, :identifier, :node_id
  end
end
