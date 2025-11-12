class AddCategoryToLmsBatches < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_batches, :category, :string
    add_index :lms_batches, :category
  end
end
