class RemoveRoleStringFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :role, :string
  end
end
