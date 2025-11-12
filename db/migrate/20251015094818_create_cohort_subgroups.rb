class CreateCohortSubgroups < ActiveRecord::Migration[7.2]
  def change
    create_table :cohort_subgroups do |t|
      # Core fields
      t.string :cohort, null: false, index: true # Link to Cohort
      t.string :slug, null: false, index: true
      t.string :title, null: false, index: true
      t.string :invite_code # Read-only field
      t.text :description # Markdown Editor

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

    # Add unique index for autoname format: {title} ({cohort})
    add_index :cohort_subgroups, [:title, :cohort], unique: true, name: 'index_cohort_subgroups_on_title_and_cohort'
  end
end
