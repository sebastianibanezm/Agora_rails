class AddRoleAndSuperadminToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :role, null: true, foreign_key: true
    add_column    :users, :superadmin, :boolean, null: false, default: false
  end
end
