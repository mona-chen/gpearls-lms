class CreateLmsExercises < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_exercises do |t|
      # Core fields
      t.string :title, null: false, index: true
      t.text :description # Small Text
      t.text :code # Code field
      t.text :answer # Code field
      t.text :hints # Small Text
      t.text :tests # Code field
      t.text :image # Code field, read-only
      t.integer :index_ # Read-only field
      t.string :index_label # Read-only field

      # Course and lesson references
      t.string :course # Link to LMS Course
      t.string :lesson # Link to Course Lesson

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
