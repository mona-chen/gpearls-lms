class AddUserCategoryToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :user_category, :string
  end
end
