class AddWebhookTokenToFlows < ActiveRecord::Migration[8.0]
  def change
    add_column :flows, :webhook_token, :string
    add_index :flows, :webhook_token, unique: true
  end
end
