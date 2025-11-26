class CreateCohortWebPages < ActiveRecord::Migration[7.0]
  def change
    create_table :cohort_web_pages do |t|
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

      # Exact Frappe field structure from cohort_web_page.json
      # This is a child table (istable: 1) with parent references
      t.string :slug, null: false                       # Data field, reqd: 1
      t.string :title, null: false                     # Data field, reqd: 1
      t.string :template, null: false                  # Link to Web Template, reqd: 1
      t.string :scope, default: "Cohort"               # Select: Cohort/Subgroup
      t.string :required_role, default: "Public"       # Select: Public/Student/Mentor/Admin

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :cohort_web_pages, :slug
    add_index :cohort_web_pages, :title
    add_index :cohort_web_pages, :template
    add_index :cohort_web_pages, :scope
    add_index :cohort_web_pages, :required_role
    add_index :cohort_web_pages, :parent
    add_index :cohort_web_pages, :parenttype
    add_index :cohort_web_pages, :parentfield
    add_index :cohort_web_pages, [ :parent, :parenttype, :parentfield ], name: 'index_cohort_web_pages_on_parent_and_type_and_field'
    add_index :cohort_web_pages, :creation
    add_index :cohort_web_pages, :modified
    add_index :cohort_web_pages, [ :slug, :title ]
    add_index :cohort_web_pages, [ :scope, :required_role ]

    # Add foreign key constraints
    # TODO: Add foreign key when web_templates table exists:
    # add_foreign_key :cohort_web_pages, :web_templates, column: :template
  end
end

### **Migration 4: exercise_latest_submission**
