class AddIdentifierToMeasurementPoints < ActiveRecord::Migration[8.0]
  def change
    add_column :measurement_points, :identifier, :string
  end
end
