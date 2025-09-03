class AddProjectToFlows < ActiveRecord::Migration[8.0]
  def change
    add_reference :flows, :project, foreign_key: true
  end
end
