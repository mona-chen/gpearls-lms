class CreateCourseCreatorRole < ActiveRecord::Migration[7.2]
  def change
    create_table :course_creator_roles do |t|
      t.string :name
      t.text :description
      t.text :permissions
      t.string :status

      t.timestamps
    end
  end
end
