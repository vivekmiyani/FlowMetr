class CreateAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :alerts do |t|
      t.references :flow, null: false, foreign_key: true
      t.references :measurement_point, null: false, foreign_key: true
      t.string :alert_type
      t.integer :threshold
      t.text :email_addresses
      t.boolean :active

      t.timestamps
    end
  end
end
