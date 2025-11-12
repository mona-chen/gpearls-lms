class CreateLmsTimetableTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_timetable_templates do |t|
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

      # Exact Frappe field structure from lms_timetable_template.json
      t.string :title                                 # Data field
      t.string :timetable                             # Table field (child table reference to LMS Batch Timetable)
      t.string :timetable_legends                    # Table field (child table reference to LMS Timetable Legend)

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_timetable_templates, :title
    add_index :lms_timetable_templates, :creation
    add_index :lms_timetable_templates, :modified
  end
end
