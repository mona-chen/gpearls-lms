class MakeFullNameNullable < ActiveRecord::Migration[7.2]
  def change
    change_column_null :users, :full_name, true
  end
end
