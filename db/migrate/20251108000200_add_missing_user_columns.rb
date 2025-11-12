class AddMissingUserColumns < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_moderator, :boolean, default: false
    add_column :users, :is_evaluator, :boolean, default: false
    add_column :users, :jti, :string
    add_index :users, :jti, unique: true
  end
end
