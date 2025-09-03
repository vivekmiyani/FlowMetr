class MakeRunUuidUniquePerFlow < ActiveRecord::Migration[8.0]
  def change
    # Remove the existing unique index on uuid
    remove_index :runs, :uuid if index_exists?(:runs, :uuid)
    
    # Add a composite unique index on flow_id and uuid
    add_index :runs, [:flow_id, :uuid], unique: true, 
      name: 'index_runs_on_flow_id_and_uuid_unique',
      where: 'uuid IS NOT NULL'
  end
end
