class CreateLmsBatchTimetables < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_batch_timetables do |t|
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

      # Exact Frappe field structure from lms_batch_timetable.json
      # This is a child table (istable: 1) with autoname: "hash"
      t.string :reference_doctype                # Link to DocType
      t.string :reference_docname                # Dynamic Link
      t.date :date                               # Date field (depends on parenttype == "LMS Batch")
      t.integer :day                             # Int field (depends on parenttype == "LMS Timetable Template")
      t.time :start_time                         # Time field
      t.time :end_time                           # Time field
      t.string :duration                         # Data field
      t.boolean :milestone, default: false       # Check field

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_batch_timetables, :reference_doctype
    add_index :lms_batch_timetables, :reference_docname
    add_index :lms_batch_timetables, :date
    add_index :lms_batch_timetables, :day
    add_index :lms_batch_timetables, :start_time
    add_index :lms_batch_timetables, :end_time
    add_index :lms_batch_timetables, :milestone
    add_index :lms_batch_timetables, :parent
    add_index :lms_batch_timetables, :parenttype
    add_index :lms_batch_timetables, :parentfield
    add_index :lms_batch_timetables, [ :parent, :parenttype, :parentfield ], name: 'index_batch_tt_on_parent_and_type_and_field'
    add_index :lms_batch_timetables, :creation
    add_index :lms_batch_timetables, :modified
    add_index :lms_batch_timetables, [ :reference_doctype, :reference_docname ], name: 'index_batch_tt_on_ref_doctype_and_docname'
    add_index :lms_batch_timetables, [ :date, :start_time ]
  end
end
