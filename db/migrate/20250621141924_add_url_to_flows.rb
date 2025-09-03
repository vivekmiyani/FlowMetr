class AddUrlToFlows < ActiveRecord::Migration[8.0]
  def change
    add_column :flows, :url, :string
  end
end
