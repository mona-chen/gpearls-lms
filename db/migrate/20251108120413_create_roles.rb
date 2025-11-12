class CreateRoles < ActiveRecord::Migration[7.2]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :role_name, null: false
      t.text :description
      t.string :status, default: "Active", null: false
      t.timestamps

      t.index :name, unique: true
      t.index :role_name, unique: true
      t.index :status
    end
  end
end
