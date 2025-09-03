class AddPublicTokenToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :public_token, :string
    add_index :projects, :public_token
  end
end
