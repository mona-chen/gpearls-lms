module System
  class UtilitiesService
    def self.get_schedule(user, params = {})
      return { error: "User not authenticated" } unless user

      # Get user's schedule including live classes, assignments, and evaluations
      schedule_items = []

      # Live classes
      live_classes = LiveClass.where(instructor: user).or(LiveClass.joins(:batch).where(batches: { instructor: user }))
      live_classes.each do |live_class|
        schedule_items << {
          id: live_class.id,
          title: live_class.title,
          type: "live_class",
          start_time: live_class.start_time,
          end_time: live_class.end_time,
          description: live_class.description,
          batch: live_class.batch&.name,
          course: live_class.batch&.course&.title
        }
      end

      # Upcoming evaluations
      evaluations = LmsAssessment.where(evaluator: user, scheduled_date: Date.today..)
      evaluations.each do |evaluation|
        schedule_items << {
          id: evaluation.id,
          title: "Assessment: #{evaluation.title}",
          type: "evaluation",
          start_time: evaluation.scheduled_date,
          end_time: evaluation.scheduled_date + (evaluation.duration || 60).minutes,
          description: evaluation.description,
          course: evaluation.course&.title
        }
      end

      # Sort by start time
      schedule_items.sort_by { |item| item[:start_time] }

      { data: schedule_items }
    rescue => e
      { error: "Failed to get schedule: #{e.message}" }
    end

    def self.report(user, report_type, params = {})
      return { error: "User not authenticated" } unless user

      case report_type
      when "course_progress"
        generate_course_progress_report(user, params)
      when "assessment_results"
        generate_assessment_results_report(user, params)
      when "certificate_status"
        generate_certificate_status_report(user, params)
      when "user_activity"
        generate_user_activity_report(user, params)
      else
        { error: "Unknown report type: #{report_type}" }
      end
    rescue => e
      { error: "Failed to generate report: #{e.message}" }
    end

    def self.send_confirmation_email(user, email_type, params = {})
      return { error: "User not authenticated" } unless user

      case email_type
      when "course_enrollment"
        send_course_enrollment_confirmation(user, params)
      when "certificate_issued"
        send_certificate_issued_confirmation(user, params)
      when "assessment_completed"
        send_assessment_completed_confirmation(user, params)
      else
        { error: "Unknown email type: #{email_type}" }
      end
    rescue => e
      { error: "Failed to send confirmation email: #{e.message}" }
    end

    def self.setup_calendar_event(user, event_data)
      return { error: "User not authenticated" } unless user

      # Create calendar event (this would integrate with Google Calendar, Outlook, etc.)
      calendar_event = CalendarEvent.new(
        user: user,
        title: event_data[:title],
        description: event_data[:description],
        start_time: event_data[:start_time] ? Time.parse(event_data[:start_time]) : nil,
        end_time: event_data[:end_time] ? Time.parse(event_data[:end_time]) : nil,
        event_type: event_data[:event_type] || "general",
        location: event_data[:location],
        attendees: event_data[:attendees] || [],
        recurrence: event_data[:recurrence],
        external_id: event_data[:external_id]
      )

      if calendar_event.save
        { success: true, event: calendar_event, message: "Calendar event created successfully" }
      else
        { error: "Failed to create calendar event", details: calendar_event.errors.full_messages }
      end
    rescue => e
      { error: "Failed to setup calendar event: #{e.message}" }
    end

    def self.update_current_membership(user, membership_data)
      return { error: "User not authenticated" } unless user

      # Find current membership
      membership = Membership.find_by(user: user, status: "Active")
      return { error: "No active membership found" } unless membership

      # Update membership
      update_attrs = {}
      update_attrs[:plan] = membership_data[:plan] if membership_data[:plan].present?
      update_attrs[:status] = membership_data[:status] if membership_data[:status].present?
      update_attrs[:renewal_date] = membership_data[:renewal_date] ? Date.parse(membership_data[:renewal_date]) : nil if membership_data[:renewal_date].present?
      update_attrs[:features] = membership_data[:features] if membership_data[:features].present?

      if membership.update(update_attrs)
        { success: true, membership: membership, message: "Membership updated successfully" }
      else
        { error: "Failed to update membership", details: membership.errors.full_messages }
      end
    rescue => e
      { error: "Failed to update membership: #{e.message}" }
    end

    def self.create_membership(user, membership_data)
      return { error: "User not authenticated" } unless user

      # Check if user already has an active membership
      existing_membership = Membership.find_by(user: user, status: "Active")
      if existing_membership
        return { error: "User already has an active membership" }
      end

      membership = Membership.new(
        user: user,
        plan: membership_data[:plan] || "Basic",
        status: "Active",
        start_date: Time.current,
        renewal_date: membership_data[:renewal_date] ? Date.parse(membership_data[:renewal_date]) : 1.month.from_now,
        features: membership_data[:features] || [],
        payment_method: membership_data[:payment_method],
        auto_renew: membership_data[:auto_renew].nil? ? true : membership_data[:auto_renew]
      )

      if membership.save
        { success: true, membership: membership, message: "Membership created successfully" }
      else
        { error: "Failed to create membership", details: membership.errors.full_messages }
      end
    rescue => e
      { error: "Failed to create membership: #{e.message}" }
    end

    def self.create_certificate_request(user, certificate_data)
      return { error: "User not authenticated" } unless user

      # Check if user has completed the course
      course = Course.find_by(id: certificate_data[:course_id])
      return { error: "Course not found" } unless course

      enrollment = Enrollment.find_by(user: user, course: course)
      return { error: "User is not enrolled in this course" } unless enrollment
      return { error: "Course not completed" } unless enrollment.completed?

      # Check if certificate request already exists
      existing_request = CertificateRequest.find_by(user: user, course: course, status: [ "Pending", "Under Review" ])
      if existing_request
        return { error: "Certificate request already exists for this course" }
      end

      certificate_request = CertificateRequest.new(
        user: user,
        course: course,
        status: "Pending",
        request_type: certificate_data[:request_type] || "Completion",
        priority: certificate_data[:priority] || "Normal",
        notes: certificate_data[:notes],
        preferred_template: certificate_data[:preferred_template],
        delivery_method: certificate_data[:delivery_method] || "Digital"
      )

      if certificate_request.save
        { success: true, request: certificate_request, message: "Certificate request created successfully" }
      else
        { error: "Failed to create certificate request", details: certificate_request.errors.full_messages }
      end
    rescue => e
      { error: "Failed to create certificate request: #{e.message}" }
    end

    def self.create_lms_certificate_evaluation(user, evaluation_data)
      return { error: "User not authenticated" } unless user
      return { error: "User is not an evaluator" } unless user.evaluator? || user.admin?

      certificate = Certificate.find_by(id: evaluation_data[:certificate_id])
      return { error: "Certificate not found" } unless certificate

      evaluation = CertificateEvaluation.new(
        certificate: certificate,
        evaluator: user,
        status: evaluation_data[:status] || "In Progress",
        score: evaluation_data[:score],
        feedback: evaluation_data[:feedback],
        criteria_scores: evaluation_data[:criteria_scores] || {},
        evaluation_date: Time.current,
        notes: evaluation_data[:notes]
      )

      if evaluation.save
        # Update certificate status if evaluation is complete
        if evaluation_data[:status] == "Completed"
          certificate.update(status: evaluation.score >= 70 ? "Approved" : "Rejected")
        end

        { success: true, evaluation: evaluation, message: "Certificate evaluation created successfully" }
      else
        { error: "Failed to create certificate evaluation", details: evaluation.errors.full_messages }
      end
    rescue => e
      { error: "Failed to create certificate evaluation: #{e.message}" }
    end

    def self.get_posthog_settings
      # Return PostHog analytics settings
      {
        posthog_project_api_key: ENV.fetch("POSTHOG_PROJECT_API_KEY", ""),
        posthog_host: ENV.fetch("POSTHOG_HOST", "https://app.posthog.com"),
        enable_analytics: ENV.fetch("ENABLE_ANALYTICS", "false") == "true",
        analytics_settings: {
          capture_pageviews: true,
          capture_clicks: true,
          mask_all_text: false,
          mask_all_element_attributes: false,
          respect_dnt: true
        }
      }
    end

    private

    def self.generate_course_progress_report(user, params)
      enrollments = user.enrollments.includes(:course)
      report_data = enrollments.map do |enrollment|
        {
          course_title: enrollment.course.title,
          progress_percentage: enrollment.progress,
          status: enrollment.status,
          enrolled_date: enrollment.created_at.strftime("%Y-%m-%d"),
          completed_date: enrollment.completed_at&.strftime("%Y-%m-%d"),
          time_spent: enrollment.time_spent || 0
        }
      end

      { report_type: "course_progress", data: report_data, generated_at: Time.current }
    end

    def self.generate_assessment_results_report(user, params)
      assessments = LmsQuizSubmission.where(student: user).includes(:quiz)
      report_data = assessments.map do |submission|
        {
          quiz_title: submission.quiz.title,
          score: submission.score,
          max_score: submission.quiz.max_score || 100,
          percentage: submission.percentage,
          status: submission.status,
          submitted_at: submission.created_at.strftime("%Y-%m-%d %H:%M:%S")
        }
      end

      { report_type: "assessment_results", data: report_data, generated_at: Time.current }
    end

    def self.generate_certificate_status_report(user, params)
      certificates = Certificate.where(user: user).includes(:course)
      report_data = certificates.map do |certificate|
        {
          certificate_name: certificate.name,
          course_title: certificate.course.title,
          status: certificate.status,
          issued_date: certificate.issued_date&.strftime("%Y-%m-%d"),
          expiry_date: certificate.expiry_date&.strftime("%Y-%m-%d"),
          download_url: certificate.download_url
        }
      end

      { report_type: "certificate_status", data: report_data, generated_at: Time.current }
    end

    def self.generate_user_activity_report(user, params)
      # Generate activity report for the specified period
      start_date = params[:start_date] ? Date.parse(params[:start_date]) : 30.days.ago
      end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today

      activities = UserActivity.where(user: user, created_at: start_date..end_date)
                              .order(created_at: :desc)

      report_data = activities.map do |activity|
        {
          activity_type: activity.activity_type,
          description: activity.description,
          timestamp: activity.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          metadata: activity.metadata
        }
      end

      { report_type: "user_activity", data: report_data, period: { start_date: start_date, end_date: end_date }, generated_at: Time.current }
    end

    def self.send_course_enrollment_confirmation(user, params)
      course = Course.find_by(id: params[:course_id])
      return { error: "Course not found" } unless course

      # Send enrollment confirmation email
      CourseEnrollmentMailer.confirmation(user, course).deliver_later

      { success: true, message: "Enrollment confirmation email sent" }
    end

    def self.send_certificate_issued_confirmation(user, params)
      certificate = Certificate.find_by(id: params[:certificate_id])
      return { error: "Certificate not found" } unless certificate

      # Send certificate issued email
      CertificateMailer.issued(user, certificate).deliver_later

      { success: true, message: "Certificate issued confirmation email sent" }
    end

    def self.send_assessment_completed_confirmation(user, params)
      assessment = LmsAssessment.find_by(id: params[:assessment_id])
      return { error: "Assessment not found" } unless assessment

      # Send assessment completion email
      AssessmentMailer.completed(user, assessment).deliver_later

      { success: true, message: "Assessment completion confirmation email sent" }
    end
  end
end
