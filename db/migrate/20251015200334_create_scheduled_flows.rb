class CreateScheduledFlows < ActiveRecord::Migration[7.2]
  def change
    create_table :scheduled_flows do |t|
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

      # Exact Frappe field structure from scheduled_flow.json
      # This is a child table (istable: 1) with parent references
      t.string :lesson, null: false                    # Link to Course Lesson, reqd: 1
      t.string :lesson_title, null: false             # Data, fetched from lesson.title
      t.date :date, null: false                        # Date field, reqd: 1
      t.time :start_time                             # Time field
      t.time :end_time                               # Time field

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :scheduled_flows, :lesson
    add_index :scheduled_flows, :lesson_title
    add_index :scheduled_flows, :date
    add_index :scheduled_flows, :start_time
    add_index :scheduled_flows, :end_time
    add_index :scheduled_flows, :parent
    add_index :scheduled_flows, :parenttype
    add_index :scheduled_flows, :parentfield
    add_index :scheduled_flows, [ :parent, :parenttype, :parentfield ], name: 'index_scheduled_flows_on_parent_and_type_and_field'
    add_index :scheduled_flows, :creation
    add_index :scheduled_flows, :modified
    add_index :scheduled_flows, [ :date, :start_time ], name: 'index_scheduled_flows_on_date_and_start_time'
    add_index :scheduled_flows, [ :date, :end_time ], name: 'index_scheduled_flows_on_date_and_end_time'

    # TODO: Add foreign key when course_lessons table exists
    # add_foreign_key :scheduled_flows, :course_lessons, column: :lesson
  end
end
