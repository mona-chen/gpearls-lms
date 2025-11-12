class CreateHasRoles < ActiveRecord::Migration[7.2]
  def change
    create_table :has_roles do |t|
      t.string :parent
      t.string :parenttype
      t.string :role
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
