class CreateCohortJoinRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :cohort_join_requests do |t|
      # Core fields
      t.string :cohort, null: false, index: true # Link to Cohort
      t.string :email, null: false, index: true # Link to User
      t.string :subgroup, null: false, index: true # Link to Cohort Subgroup
      t.string :status, null: false, default: "Pending", index: true # Pending, Accepted, Rejected

      # Frappe standard fields
      t.string :name, null: false, index: { unique: true }
      t.string :owner
      t.datetime :creation
      t.datetime :modified

      # Rails timestamps
      t.timestamps
    end

    # Indexes already added by t.index in create_table
  end
end
