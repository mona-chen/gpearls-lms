class CreateLmsSidebarItems < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_sidebar_items do |t|
      # Frappe standard fields
      t.string :name, null: false
      t.string :owner, null: false
      t.datetime :creation, null: false
      t.datetime :modified, null: false
      t.string :modified_by, null: false
      t.string :docstatus, default: "0"
      t.string :parent, null: true
      t.string :parenttype, null: true
      t.string :parentfield, null: true
      t.integer :idx, null: true

      # Exact Frappe field structure from lms_sidebar_item.json
      # This is a child table (istable: 1) with parent references
      t.string :web_page, null: false               # Link to Web Page, reqd: 1
      t.string :title                              # Data, fetched from web_page.title
      t.string :icon, null: false                   # Data, fetched from web_page.icon, read_only: 1, reqd: 1
      t.string :route                              # Data, fetched from web_page.route

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_sidebar_items, :web_page
    add_index :lms_sidebar_items, :title
    add_index :lms_sidebar_items, :icon
    add_index :lms_sidebar_items, :route
    add_index :lms_sidebar_items, :parent
    add_index :lms_sidebar_items, :parenttype
    add_index :lms_sidebar_items, :parentfield
    add_index :lms_sidebar_items, [:parent, :parenttype, :parentfield], name: 'index_sidebar_items_on_parent_and_type_and_field'
    add_index :lms_sidebar_items, :creation
    add_index :lms_sidebar_items, :modified
    add_index :lms_sidebar_items, [:web_page, :title]
  end
end
