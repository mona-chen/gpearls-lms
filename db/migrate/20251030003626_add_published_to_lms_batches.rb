class AddPublishedToLmsBatches < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_batches, :published, :boolean, default: false
    add_index :lms_batches, :published
  end
end
