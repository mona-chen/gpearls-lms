module Analytics
  class CourseAnalyticsService
    def self.get_completion_data
      # Real course completion data based on lesson progress
      courses = Course.includes(:enrollments, :lessons)

      completion_data = courses.map do |course|
        total_students = course.enrollments.count
        next if total_students == 0

        # Calculate actual completion based on lesson progress
        completed_students = 0
        course.enrollments.each do |enrollment|
          total_lessons = course.lessons.count
          if total_lessons > 0
            completed_lessons = LessonProgress.joins(:lesson)
              .where(user: enrollment.user, completed: true)
              .where("course_lessons.course = ?", course.id.to_s)
              .count

            completed_students += 1 if (completed_lessons.to_f / total_lessons * 100) >= 80.0
          end
        end

        completion_rate = (completed_students.to_f / total_students * 100).round(2)

        {
          course_name: course.title,
          course_id: course.id,
          total_students: total_students,
          completed_students: completed_students,
          completion_rate: completion_rate
        }
      end.compact

      completion_data
    end

    def self.get_progress_distribution(course_id)
      return [] unless course_id

      course = Course.find_by(id: course_id)
      return [] unless course

      enrollments = course.enrollments.pluck(:progress)

      distribution = [
        { category: "0-20%", count: enrollments.count { |p| p >= 0 && p < 20 } },
        { category: "20-40%", count: enrollments.count { |p| p >= 20 && p < 40 } },
        { category: "40-60%", count: enrollments.count { |p| p >= 40 && p < 60 } },
        { category: "60-80%", count: enrollments.count { |p| p >= 60 && p < 80 } },
        { category: "80-100%", count: enrollments.count { |p| p >= 80 && p <= 100 } }
      ]

      average_progress = enrollments.empty? ? 0 : (enrollments.sum.to_f / enrollments.size).round(2)

      {
        average_progress: average_progress,
        progress_distribution: distribution
      }
    end
  end
end
