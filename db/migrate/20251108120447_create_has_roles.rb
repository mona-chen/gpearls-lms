class CreateHasRoles < ActiveRecord::Migration[7.2]
  def change
    create_table :has_roles do |t|
      t.string :parent, null: false
      t.string :parenttype, null: false
      t.string :role, null: false
      t.references :user, null: false, foreign_key: true
      t.timestamps

      t.index [ :parent, :role, :user_id ], unique: true, name: 'index_has_roles_on_parent_role_user_id'
      t.index :user_id, name: 'index_has_roles_on_user_id_unique'
      t.index :role, name: 'index_has_roles_on_role'
      t.index :parent, name: 'index_has_roles_on_parent'
    end
  end
end
