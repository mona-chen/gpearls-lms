class CreatePermissions < ActiveRecord::Migration[7.2]
  def change
    create_table :permissions do |t|
      t.string :name
      t.string :description
      t.string :doctype
      t.string :action
      t.string :role

      t.timestamps
    end
  end
end
