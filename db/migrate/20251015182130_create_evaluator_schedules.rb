class CreateEvaluatorSchedules < ActiveRecord::Migration[7.0]
  def change
    create_table :evaluator_schedules do |t|
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

      # Exact Frappe field structure from evaluator_schedule.json
      # This is a child table (istable: 1) with autoname: "autoincrement"
      t.string :day, null: false                       # Select: Sunday/Monday/Tuesday/Wednesday/Thursday/Friday/Saturday, reqd: 1
      t.time :start_time, null: false                 # Time field, reqd: 1
      t.time :end_time, null: false                   # Time field, reqd: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :evaluator_schedules, :day
    add_index :evaluator_schedules, :start_time
    add_index :evaluator_schedules, :end_time
    add_index :evaluator_schedules, :parent
    add_index :evaluator_schedules, :parenttype
    add_index :evaluator_schedules, :parentfield
    add_index :evaluator_schedules, [:parent, :parenttype, :parentfield], name: 'index_evaluator_schedules_on_parent_and_type_and_field'
    add_index :evaluator_schedules, :creation
    add_index :evaluator_schedules, :modified
    add_index :evaluator_schedules, [:day, :start_time], name: 'index_evaluator_schedules_on_day_and_start_time'
    add_index :evaluator_schedules, [:day, :end_time], name: 'index_evaluator_schedules_on_day_and_end_time'
  end
end
