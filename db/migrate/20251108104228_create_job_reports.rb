class CreateJobReports < ActiveRecord::Migration[7.2]
  def change
    create_table :job_reports do |t|
      t.string :job_opportunity, null: false
      t.string :reported_by, null: false
      t.string :reason, null: false
      t.text :description
      t.string :status, default: 'pending'
      t.string :owner
      t.datetime :creation
      t.datetime :modified
      t.string :modified_by
      t.timestamps
    end

    add_index :job_reports, :job_opportunity
    add_index :job_reports, :reported_by
    add_index :job_reports, :status
  end
end
