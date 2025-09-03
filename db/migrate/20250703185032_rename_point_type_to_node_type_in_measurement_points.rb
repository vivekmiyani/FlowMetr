class RenamePointTypeToNodeTypeInMeasurementPoints < ActiveRecord::Migration[8.0]
  def change
    rename_column :measurement_points, :point_type, :node_type
  end
end
