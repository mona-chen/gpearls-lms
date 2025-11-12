class CreateCohortMentors < ActiveRecord::Migration[7.2]
  def change
    create_table :cohort_mentors do |t|
      # Core fields
      t.string :cohort, null: false, index: true # Link to Cohort
      t.string :email, null: false, index: true # Link to User
      t.string :subgroup, null: false, index: true # Link to Cohort Subgroup

      # Course reference (fetched field)
      t.string :course # Link to LMS Course

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
