class AddSequenceToMeasurementPoints < ActiveRecord::Migration[8.0]
  def change
    add_column :measurement_points, :sequence, :integer
  end
end
