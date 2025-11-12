class AddUpcomingToLmsCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_courses, :upcoming, :boolean
  end
end
