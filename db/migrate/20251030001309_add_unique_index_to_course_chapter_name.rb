class AddUniqueIndexToCourseChapterName < ActiveRecord::Migration[7.2]
  def change
    add_index :course_chapters, :name, unique: true
  end
end
