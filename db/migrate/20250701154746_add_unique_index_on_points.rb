class AddUniqueIndexOnPoints < ActiveRecord::Migration[7.1]
  def change
    add_index :measurement_points, %i[flow_id identifier], unique: true
    remove_column :measurement_points, :webhook_token, :string
  end
end