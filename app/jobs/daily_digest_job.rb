class DailyDigestJob < ApplicationJob
  queue_as :default
  
  # Matches Frappe's daily digest email functionality
  def perform(date = Date.current)
    Rails.logger.info "Starting daily digest job for #{date}"
    
    # Get all users who have opted for daily digest
    users_with_digest = User.where(email_preferences: { daily_digest: true })
                           .or(User.where(daily_digest_enabled: true))
    
    users_with_digest.find_each do |user|
      begin
        send_daily_digest_to_user(user, date)
      rescue => e
        Rails.logger.error "Failed to send daily digest to #{user.email}: #{e.message}"
      end
    end
    
    Rails.logger.info "Daily digest job completed for #{date}"
  end
  
  private
  
  def send_daily_digest_to_user(user, date)
    digest_data = compile_user_digest(user, date)
    
    # Skip if no significant activity
    return if digest_data[:activities].empty? && digest_data[:notifications].empty?
    
    # Send email using EmailNotificationJob
    EmailNotificationJob.perform_later(
      'NotificationMailer',
      'daily_digest',
      user,
      digest_data,
      date
    )
  end
  
  def compile_user_digest(user, date)
    start_time = date.beginning_of_day
    end_time = date.end_of_day
    
    {
      user: user,
      date: date,
      activities: get_user_activities(user, start_time, end_time),
      notifications: get_user_notifications(user, start_time, end_time),
      course_updates: get_course_updates(user, start_time, end_time),
      upcoming_events: get_upcoming_events(user),
      assignments_due: get_assignments_due(user),
      certificates_earned: get_certificates_earned(user, start_time, end_time),
      discussion_mentions: get_discussion_mentions(user, start_time, end_time)
    }
  end
  
  def get_user_activities(user, start_time, end_time)
    activities = []
    
    # Lesson completions
    lesson_completions = LessonProgress.where(
      user: user,
      status: 'Complete',
      updated_at: start_time..end_time
    ).includes(:lesson)
    
    lesson_completions.each do |progress|
      activities << {
        type: 'lesson_completed',
        title: progress.lesson.title,
        course: progress.lesson.course.title,
        timestamp: progress.updated_at
      }
    end
    
    # Quiz submissions
    quiz_submissions = QuizSubmission.where(
      user: user,
      created_at: start_time..end_time
    ).includes(:quiz)
    
    quiz_submissions.each do |submission|
      activities << {
        type: 'quiz_submitted',
        title: submission.quiz.title,
        score: submission.score,
        timestamp: submission.created_at
      }
    end
    
    # Course enrollments
    enrollments = Enrollment.where(
      user: user,
      created_at: start_time..end_time
    ).includes(:course)
    
    enrollments.each do |enrollment|
      activities << {
        type: 'course_enrolled',
        title: enrollment.course.title,
        timestamp: enrollment.created_at
      }
    end
    
    activities.sort_by { |a| a[:timestamp] }.reverse
  end
  
  def get_user_notifications(user, start_time, end_time)
    if defined?(Notification)
      Notification.where(
        user: user,
        created_at: start_time..end_time
      ).where.not(notification_type: 'email')
       .order(created_at: :desc)
       .limit(10)
    else
      []
    end
  end
  
  def get_course_updates(user, start_time, end_time)
    enrolled_courses = user.courses
    updates = []
    
    enrolled_courses.each do |course|
      # New lessons added
      new_lessons = course.course_lessons.where(created_at: start_time..end_time)
      new_lessons.each do |lesson|
        updates << {
          type: 'new_lesson',
          course_title: course.title,
          lesson_title: lesson.title,
          timestamp: lesson.created_at
        }
      end
      
      # Course announcements
      if defined?(Announcement)
        announcements = Announcement.where(
          course: course,
          created_at: start_time..end_time
        )
        
        announcements.each do |announcement|
          updates << {
            type: 'announcement',
            course_title: course.title,
            title: announcement.title,
            content: announcement.content,
            timestamp: announcement.created_at
          }
        end
      end
    end
    
    updates.sort_by { |u| u[:timestamp] }.reverse.first(5)
  end
  
  def get_upcoming_events(user)
    events = []
    
    # Upcoming live classes
    if defined?(LiveClass)
      upcoming_classes = LiveClass.joins(:batch)
                                 .joins("JOIN batch_enrollments ON batches.id = batch_enrollments.batch_id")
                                 .where("batch_enrollments.user_id = ?", user.id)
                                 .where("start_time > ?", Time.current)
                                 .where("start_time < ?", 7.days.from_now)
                                 .order(:start_time)
                                 .limit(3)
      
      upcoming_classes.each do |live_class|
        events << {
          type: 'live_class',
          title: live_class.title,
          start_time: live_class.start_time,
          course_title: live_class.batch.course.title
        }
      end
    end
    
    events
  end
  
  def get_assignments_due(user)
    if defined?(Assignment)
      Assignment.joins(:course)
                .joins("JOIN enrollments ON courses.id = enrollments.course_id")
                .where("enrollments.user_id = ?", user.id)
                .where("due_date > ?", Time.current)
                .where("due_date < ?", 3.days.from_now)
                .order(:due_date)
                .limit(5)
    else
      []
    end
  end
  
  def get_certificates_earned(user, start_time, end_time)
    if defined?(Certificate)
      Certificate.where(
        user: user,
        created_at: start_time..end_time
      ).includes(:course)
    else
      []
    end
  end
  
  def get_discussion_mentions(user, start_time, end_time)
    if defined?(Message)
      Message.where("content ILIKE ?", "%@#{user.email}%")
             .where(created_at: start_time..end_time)
             .includes(:discussion)
             .limit(5)
    else
      []
    end
  end
end