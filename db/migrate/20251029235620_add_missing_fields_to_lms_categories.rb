class AddMissingFieldsToLmsCategories < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_categories, :position, :integer, default: 0, null: false
    add_column :lms_categories, :is_active, :boolean, default: true, null: false

    # Add index for position field
    add_index :lms_categories, :position
    add_index :lms_categories, :is_active
  end
end
