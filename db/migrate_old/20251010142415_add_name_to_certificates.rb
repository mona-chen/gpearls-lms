class AddNameToCertificates < ActiveRecord::Migration[7.2]
  def change
    add_column :certificates, :name, :string
  end
end
