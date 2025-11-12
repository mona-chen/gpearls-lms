class CreateLmsCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_categories do |t|
      # LMS Categories specific fields (based on Frappe Course Category doctype)
      t.string :name, null: false                    # Category name (primary field)
      t.string :description                          # Category description
      t.string :parent_category, null: true          # Parent category for hierarchy
      t.integer :lft, null: true                     # Left value for nested set
      t.integer :rght, null: true                    # Right value for nested set
      t.integer :depth, null: true                   # Depth in hierarchy
      t.string :icon, null: true                     # Icon for category
      t.string :color, null: true                    # Color code for category
      t.boolean :is_group, default: false            # Whether this is a group category
      t.integer :old_parent, null: true              # Previous parent for tracking
      t.string :route                                # URL route for category
      t.boolean :published, default: true            # Whether category is published
      t.integer :course_count, default: 0            # Number of courses in this category
      t.text :custom_fields                          # Custom fields (JSON)

      t.timestamps
    end

    # Add indexes for performance and hierarchy queries
    add_index :lms_categories, :name, unique: true
    add_index :lms_categories, :parent_category
    add_index :lms_categories, [:lft, :rght]
    add_index :lms_categories, :depth
    add_index :lms_categories, :published
    add_index :lms_categories, :course_count
    add_index :lms_categories, :route
  end
end
