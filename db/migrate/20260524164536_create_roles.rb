class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string     :name,         null: false
      t.string     :description
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end

    add_index :roles, %i[organization_id name], unique: true
  end
end
