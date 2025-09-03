class CreateCheckpoints < ActiveRecord::Migration[8.0]
  def change
    create_table :measurement_logs do |t|
      t.references :run, null: false, foreign_key: true
      t.references :measurement_point, null: false, foreign_key: true
      t.datetime :received_at

      t.timestamps
    end
  end
end
