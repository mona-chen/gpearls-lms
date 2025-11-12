class AddProfileFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :headline, :text
    add_column :users, :bio, :text
    add_column :users, :description, :text
    add_column :users, :github, :string
    add_column :users, :linkedin, :string
    add_column :users, :website, :string
    add_column :users, :company, :string
    add_column :users, :phone, :string
    add_column :users, :location, :string
  end
end
