class AddSecretTokenToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :secret_token, :string
    add_index :projects, :secret_token, unique: true

    # Generate secret tokens for existing projects
    Project.find_each do |project|
      project.update_columns(secret_token: SecureRandom.hex(32))
    end

    change_column_null :projects, :secret_token, false
  end
end
