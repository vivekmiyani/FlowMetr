class CreateMeasurementPoints < ActiveRecord::Migration[8.0]
  def change
    create_table :measurement_points do |t|
      t.string :name
      t.string :point_type
      t.string :webhook_token
      t.references :flow, null: false, foreign_key: true

      t.timestamps
    end
  end
end
