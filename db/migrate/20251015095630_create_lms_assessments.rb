class CreateLmsAssessments < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_assessments do |t|
      # This is a child table (istable: 1 in Frappe), so it needs parent reference
      # In Frappe, child tables are associated with their parent through parent field

      # Reference to parent assessment (this will be filled by the parent)
      t.string :parent, null: false, index: true
      t.string :parenttype, null: false
      t.integer :parentfield, null: false, default: 0

      # Core fields
      t.string :assessment_type, null: false, index: true # Link to DocType
      t.string :assessment_name, null: false # Dynamic Link based on assessment_type

      # Frappe standard fields for child tables
      t.string :name, null: false, index: { unique: true }
      t.string :owner
      t.datetime :creation
      t.datetime :modified

      # Rails timestamps
      t.timestamps
    end

    # Indexes already added by t.index in create_table

    # Index for parent-child relationship already added by t.index in create_table
  end
end
