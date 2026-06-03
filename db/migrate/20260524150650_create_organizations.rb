class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.string :plan, null: false, default: "starter"
      t.jsonb :features, null: false, default: {}

      t.timestamps
    end
    add_index :organizations, :subdomain, unique: true
  end
end
