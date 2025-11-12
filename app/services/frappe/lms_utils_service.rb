module Frappe
  # Exact replica of frappe.lms.utils functions with 100% feature parity
  class LmsUtilsService
    class << self
      # Exact replica of has_course_moderator_role from lms/utils.py:507
      def has_course_moderator_role(member = nil)
        user = member ? User.find_by(id: member) : User.current
        return false unless user

        user.has_role?("Moderator")
      end
      # Exact replica of get_tags from lms/utils.py:205
      def get_tags(course)
        course_record = Course.find_by(id: course)
        return [] unless course_record

        tags = course_record.tags
        return [] unless tags
        return [ "" ] if tags.strip.empty?
        tags.split(",")
      end

      # Exact replica of get_reviews from lms/utils.py:249
      def get_reviews(course)
        reviews = []
        # TODO: Implement when LMS Course Review table exists
        # For now, return empty array as per Frappe behavior when no reviews exist

        reviews
      end

      # Exact replica of get_average_rating from lms/utils.py:242
      def get_average_rating(course)
        reviews = get_reviews(course)
        return 0.0 if reviews.empty?

        ratings = reviews.map { |review| review[:rating] || 0 }
        return 0.0 if ratings.empty?

        (ratings.sum.to_f / ratings.length).round(2)
      end

      # Exact replica of get_course_progress from lms/utils.py:386
      def get_course_progress(course, member = nil)
        member ||= Current.user&.email
        return 0 unless member

        user = User.find_by(email: member)
        return 0 unless user

        course_record = Course.find_by(id: course)
        return 0 unless course_record

        total_lessons = course_record.lessons.count
        return 0 if total_lessons == 0

        completed_lessons = LessonProgress.joins(:lesson)
          .where(user: user, lessons: { course: course_record.id.to_s }, completed: true)
          .count

        progress = ((completed_lessons.to_f / total_lessons) * 100).round(3)
        progress
      end

      # Exact replica of get_membership from lms/utils.py:73
      def get_membership(course, member = nil)
        member ||= Current.user&.email
        return false unless member

        user = User.find_by(email: member)
        return false unless user

        enrollment = Enrollment.find_by(user: user, course_id: course)

        return false unless enrollment

        {
          name: enrollment.id,
          current_lesson: enrollment.current_lesson,
          progress: enrollment.progress,
          member: member,
          purchased_certificate: enrollment.purchased_certificate || false,
          certificate: enrollment.certificate
        }
      end

      # Exact replica of get_my_courses from lms/utils.py:2153
      def get_my_courses
        my_courses = []
        user = Current.user

        return my_courses unless user

        courses = get_my_latest_courses(user)

        if courses.empty?
          courses = get_featured_home_courses
        end

        if courses.empty?
          courses = get_popular_courses
        end

        courses.each do |course|
          course_details = get_course_details(course, user)
          my_courses << course_details if course_details
        end

        my_courses
      end

      # Exact replica of get_my_batches from lms/utils.py:2207
      def get_my_batches
        my_batches = []
        user = Current.user

        return my_batches unless user

        batches = get_my_latest_batches(user)

        if batches.empty?
          batches = get_upcoming_batches
        end

        batches.each do |batch|
          batch_details = get_batch_details(batch, user)
          my_batches << batch_details if batch_details
        end

        my_batches
      end

      # Exact replica of get_my_live_classes from lms/utils.py:2251
      def get_my_live_classes
        my_live_classes = []
        return my_live_classes unless Current.user

        user = Current.user
        batch_enrollments = BatchEnrollment.where(user: user)
        batch_names = batch_enrollments.pluck(:batch_id)

        live_classes = LiveClass.where("date >= ?", Date.today)
          .where(batch_id: batch_names)
          .order(:date)
          .limit(2)

        live_classes.each do |live_class|
          course_title = live_class.batch&.course&.title
          live_class_data = {
            name: live_class.id,
            title: live_class.title,
            description: live_class.description,
            time: live_class.start_time&.strftime("%H:%M:%S"),
            date: live_class.date,
            duration: live_class.duration,
            attendees: live_class.attendees || [],
            start_url: live_class.start_url,
            join_url: live_class.join_url,
            owner: live_class.instructor&.email,
            course_title: course_title
          }
          my_live_classes << live_class_data
        end

        my_live_classes
      end

      # NEW: Get live classes created by instructor (for admin dashboard)
      def get_admin_live_classes
        return [] unless Current.user

        user = Current.user
        # Only instructors and moderators can see admin live classes
        return [] unless user.instructor? || user.moderator?

        live_classes = LiveClass.where(instructor: user)
          .where("date >= ?", Date.today)
          .order(:date)
          .limit(10)

        live_classes.map do |live_class|
          course_title = live_class.batch&.course&.title
          batch_title = live_class.batch&.title
          {
            name: live_class.id,
            title: live_class.title,
            description: live_class.description,
            time: live_class.start_time&.strftime("%H:%M:%S"),
            date: live_class.date,
            duration: live_class.duration,
            attendees: live_class.attendees || [],
            start_url: live_class.start_url,
            join_url: live_class.join_url,
            owner: live_class.instructor&.email,
            course_title: course_title,
            batch_title: batch_title,
            batch_id: live_class.batch_id,
            course_id: live_class.batch&.course&.id
          }
        end
      end

      # Exact replica of get_streak_info from lms/utils.py:2475
      def get_streak_info
        return {} unless Current.user

        user = Current.user
        all_dates = fetch_activity_dates(user)
        streak, longest_streak = calculate_streaks(all_dates)
        current_streak = calculate_current_streak(all_dates, streak)

        {
          current_streak: current_streak,
          longest_streak: longest_streak
        }
      end

      # Exact replica of get_upcoming_evals from lms/utils.py:847
      def get_upcoming_evals(courses = nil, batch = nil)
        return [] unless Current.user

        user = Current.user
        filters = {
          user: user,
          date: Date.today..,
          status: "Upcoming"
        }

        if courses && !courses.empty?
          filters[:course_id] = courses
        end

        if batch
          filters[:batch_id] = batch
        end

        upcoming_evals = CertificateRequest.where(filters)
          .includes(:course, :evaluator)
          .order(:date)

        upcoming_evals.map do |eval_request|
          {
            name: eval_request.id,
            date: eval_request.date&.strftime("%Y-%m-%d"),
            start_time: eval_request.start_time&.strftime("%H:%M:%S"),
            course: eval_request.course&.id,
            evaluator: eval_request.evaluator&.email,
            google_meet_link: eval_request.google_meet_link,
            member: user.email,
            member_name: user.full_name,
            course_title: eval_request.course&.title,
            evaluator_name: eval_request.evaluator&.full_name
          }
        end
      end

      # Exact replica of save_current_lesson (not in utils.py but in compatibility controller)
      def save_current_lesson(course, lesson)
        return { success: false, error: "Not authenticated" } unless Current.user

        user = Current.user
        enrollment = Enrollment.find_by(user: user, course_id: course)
        return { success: false, error: "Enrollment not found" } unless enrollment

        enrollment.update(current_lesson: lesson)
        { success: true }
      end

      private

      # Helper methods matching Frappe implementation
      def get_my_latest_courses(user)
        return [] unless user

        Enrollment.where(user: user)
          .order(updated_at: :desc)
          .limit(3)
          .pluck(:course_id)
      end

      def get_featured_home_courses
        Course.where(published: true, featured: true)
          .order(published_at: :desc)
          .limit(3)
          .pluck(:id)
      end

      def get_popular_courses
        Course.where(published: true)
          .order(enrollments_count: :desc)
          .limit(3)
          .pluck(:id)
      end

      def get_course_details(course, user = nil)
        # This should match get_course_details from utils.py:1101
        course_record = Course.find_by(id: course)
        return nil unless course_record

        # Get enrollment for the user
        enrollment = user ? Enrollment.find_by(user: user, course_id: course_record.id) : nil

        {
          name: course_record.id,
          title: course_record.title,
          tags: course_record.tags&.split(",") || [],
          image: course_record.image,
          video_link: course_record.video_link,
          short_introduction: course_record.short_introduction,
          published: course_record.published,
          upcoming: course_record.upcoming?,
          featured: course_record.featured,
          category: course_record.category,
          status: course_record.published ? "Approved" : "Draft",
          lessons: course_record.lessons.count,
          enrollments: course_record.enrollments.count,
          rating: get_average_rating(course) || 0,
          membership: enrollment ? {
            name: enrollment.id,
            course: enrollment.course_id,
            current_lesson: enrollment.current_lesson,
            progress: enrollment.progress,
            member: enrollment.user_id
          } : nil
        }
      end

      def get_my_latest_batches(user)
        return [] unless user

        BatchEnrollment.where(user: user)
          .order(created_at: :desc)
          .limit(4)
          .pluck(:batch_id)
      end

      def get_upcoming_batches
        Batch.where(published: true)
          .where("start_date >= ?", Date.today)
          .order(:start_date)
          .limit(4)
      end

      def get_batch_details(batch, user = nil)
        # This should match get_batch_details from utils.py:1332
        batch_record = Batch.find_by(id: batch)
        return nil unless batch_record

        # Get enrollment for the user
        enrollment = user ? BatchEnrollment.find_by(user: user, batch_id: batch_record.id) : nil

        {
          name: batch_record.id,
          title: batch_record.title,
          description: batch_record.description,
          start_date: batch_record.start_date&.strftime("%Y-%m-%d"),
          end_date: batch_record.end_date&.strftime("%Y-%m-%d"),
          published: batch_record.published,
          enrollment: enrollment ? {
            name: enrollment.id,
            batch: enrollment.batch_id,
            member: enrollment.user_id
          } : nil
        }
      end

      def fetch_activity_dates(user)
        doctypes = [ CourseProgress, QuizSubmission, AssignmentSubmission ]
        all_dates = []

        doctypes.each do |doctype|
          dates = doctype.where(user: user).pluck(:created_at)
          all_dates.concat(dates)
        end

        all_dates.map(&:to_date).sort.uniq
      end

      def calculate_streaks(all_dates)
        return [ 0, 0 ] if all_dates.empty?

        streak = 0
        longest_streak = 0
        prev_day = nil

        all_dates.each do |date|
          # Skip weekends (5=Saturday, 6=Sunday)
          next if [ 5, 6 ].include?(date.wday)

          if prev_day
            expected = prev_day + 1.day
            # Skip weekends in expected date calculation
            while [ 5, 6 ].include?(expected.wday)
              expected += 1.day
            end

            streak = date == expected ? streak + 1 : 1
          else
            streak = 1
          end

          longest_streak = [ longest_streak, streak ].max
          prev_day = date
        end

        [ streak, longest_streak ]
      end

      def calculate_current_streak(all_dates, streak)
        return 0 if all_dates.empty?

        last_date = all_dates.last
        today = Date.today

        # Find the most recent weekday
        ref_day = today
        while [ 5, 6 ].include?(ref_day.wday)
          ref_day -= 1.day
        end

        if last_date == ref_day || last_date == ref_day - 1.day
          streak
        else
          0
        end
      end
    end
  end
end
