class AddPublishedAtToCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :courses, :published_at, :datetime
  end
end
