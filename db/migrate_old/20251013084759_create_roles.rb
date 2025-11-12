class CreateRoles < ActiveRecord::Migration[7.2]
  def change
    create_table :roles do |t|
      t.string :name
      t.string :role_name
      t.text :description
      t.boolean :desk_access
      t.string :home_page
      t.string :status
      t.timestamps
    end
  end
end
