class CreateCertificationCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :certification_categories do |t|
      t.string :name
      t.text :description
      t.boolean :enabled

      t.timestamps
    end
  end
end
