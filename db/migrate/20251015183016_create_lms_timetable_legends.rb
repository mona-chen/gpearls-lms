class CreateLmsTimetableLegends < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_timetable_legends do |t|
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

      # Exact Frappe field structure from lms_timetable_legend.json
      # This is a child table (istable: 1) with parent references
      t.string :reference_doctype, null: false    # Link to DocType, reqd: 1
      t.string :label, null: false                # Data field, reqd: 1
      t.string :color, null: false                # Color field, reqd: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_timetable_legends, :reference_doctype
    add_index :lms_timetable_legends, :label
    add_index :lms_timetable_legends, :color
    add_index :lms_timetable_legends, :parent
    add_index :lms_timetable_legends, :parenttype
    add_index :lms_timetable_legends, :parentfield
    add_index :lms_timetable_legends, [ :parent, :parenttype, :parentfield ], name: 'index_timetable_legends_on_parent_and_type_and_field'
    add_index :lms_timetable_legends, :creation
    add_index :lms_timetable_legends, :modified
    add_index :lms_timetable_legends, [ :reference_doctype, :label ]
    add_index :lms_timetable_legends, [ :reference_doctype, :color ]
  end
end
