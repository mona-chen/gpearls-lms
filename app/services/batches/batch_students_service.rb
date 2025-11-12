module Batches
  class BatchStudentsService
    def self.call(batch_name, status_filter = nil)
      new(batch_name, status_filter).call
    end

    def initialize(batch_name, status_filter)
      @batch_name = batch_name
      @status_filter = status_filter
    end

    def call
      # Find batch by name (parameterized title), title, or id
      batch = Batch.find_by(title: @batch_name) ||
              Batch.find_by(id: @batch_name) ||
              Batch.where("title LIKE ?", @batch_name.tr("_", " ")).first
      return [] unless batch

      enrollments = BatchEnrollment.by_batch(batch).includes(:user, :payment)

      # Apply status filter
      case @status_filter
      when "active"
        enrollments = enrollments.active
      when "upcoming"
        enrollments = enrollments.upcoming
      when "completed"
        enrollments = enrollments.completed
      end

      enrollments.map do |enrollment|
        user = enrollment.user
        progress = calculate_user_progress(user, batch)
        last_activity = get_last_activity(user, batch)

        # Frappe-compatible format matching lms/utils.py get_batch_students
        enrollment.to_frappe_format.merge(
          user_details: {
            email: user.email,
            name: user.full_name,
            username: user.username,
            user_image: user.user_image
          },
          progress: progress,
          certificates: Certificate.where(user: user, batch: batch).published.count,
          last_activity: last_activity&.strftime("%Y-%m-%d %H:%M:%S")
        )
      end
    end

    private

    def calculate_user_progress(user, batch)
      return 0 unless user && batch

      total_lessons = batch.courses.joins(chapters: :lessons).count
      return 0 if total_lessons == 0

      # Use string-based course names for Frappe compatibility
      course_names = batch.courses.pluck(:title)
      completed_lessons = CourseProgress.where(member: user.email)
                                         .where(course: course_names)
                                         .where(status: "Complete")
                                         .count

      (completed_lessons.to_f / total_lessons * 100).round(2)
    end

    def get_last_activity(user, batch)
      return nil unless user && batch

      # Use string-based course names for Frappe compatibility
      course_names = batch.courses.pluck(:title)
      activity = CourseProgress.where(member: user.email)
                               .where(course: course_names)
                               .order(updated_at: :desc)
                               .first

      activity&.updated_at
    end
  end
end
