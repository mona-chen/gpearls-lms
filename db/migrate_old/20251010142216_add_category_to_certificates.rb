class AddCategoryToCertificates < ActiveRecord::Migration[7.2]
  def change
    add_column :certificates, :category, :string
  end
end
