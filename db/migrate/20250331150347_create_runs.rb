class CreateRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :runs do |t|
      t.references :flow, null: false, foreign_key: true
      t.string :status
      t.datetime :started_at
      t.datetime :ended_at
      t.float :duration
      t.boolean :error
      t.string :uuid

      t.timestamps
    end
    add_index :runs, :uuid, unique: true
  end
end
