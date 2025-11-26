module Batches
  class BatchService
    def self.calculate_user_progress_for_batch(user, batch)
      total_lessons = batch.courses.joins(:lessons).count
      return 0 if total_lessons == 0

      completed_lessons = user.lesson_progress
                              .joins(lesson: :chapter)
                              .where(chapters: { course: batch.courses })
                              .where(status: "Complete")
                              .count

      (completed_lessons.to_f / total_lessons * 100).round(2)
    end

    def self.get_last_activity_for_batch(user, batch)
      activity = user.lesson_progress
                     .joins(lesson: :chapter)
                     .where(chapters: { course: batch.courses })
                     .order(:updated_at)
                     .last

      activity&.updated_at
    end

    def self.get_batch_timetable(batch)
      batch_timetable = BatchTimetable.where(batch: batch)
                                       .includes(:reference_doc)
                                       .order(:date, :start_time)

      # Include live classes if enabled
      live_classes = []
      if batch.show_live_class
        live_classes = LiveClass.where(batch_name: batch.name)
                                .order(:date, :time)
                                .map do |live_class|
          {
            name: live_class.name,
            title: live_class.title,
            date: live_class.date.strftime("%Y-%m-%d"),
            start_time: live_class.time.strftime("%H:%M:%S"),
            end_time: (live_class.time + live_class.duration.minutes).strftime("%H:%M:%S"),
            reference_doctype: "LMS Live Class",
            reference_docname: live_class.name,
            url: live_class.join_url,
            duration: live_class.duration,
            milestone: false
          }
        end
      end

      timetable_entries = batch_timetable.map do |entry|
        {
          name: entry.name,
          title: entry.reference_doc&.title,
          date: entry.date.strftime("%Y-%m-%d"),
          start_time: entry.start_time&.strftime("%H:%M:%S"),
          end_time: entry.end_time&.strftime("%H:%M:%S"),
          reference_doctype: entry.reference_doctype,
          reference_docname: entry.reference_docname,
          milestone: entry.milestone
        }
      end

      (timetable_entries + live_classes).sort_by { |entry| [ entry[:date], entry[:start_time] || entry[:time] ] }
    end

    def self.create_live_class(params)
      batch = Batch.find(params[:batch_name])
      return { error: "Batch not found" } unless batch

      # Validate Zoom account
      zoom_account = ZoomSetting.find_by(account_name: params[:zoom_account])
      return { error: "Zoom account not configured" } unless zoom_account

      # Create live class record
      live_class = LiveClass.new(
        title: params[:title],
        description: params[:description],
        batch_name: batch.name,
        date: params[:date],
        time: params[:time],
        duration: params[:duration],
        auto_recording: params[:auto_recording] || "No Recording",
        zoom_account: zoom_account.name,
        host: Current.user&.email
      )

      # Call Zoom API to create meeting
      zoom_response = create_zoom_meeting(zoom_account, params)

      if zoom_response[:success]
        live_class.start_url = zoom_response[:start_url]
        live_class.join_url = zoom_response[:join_url]
        live_class.meeting_id = zoom_response[:meeting_id]
        live_class.uuid = zoom_response[:uuid]
        live_class.password = zoom_response[:password]

        if live_class.save
          # Add all batch students to the event
          add_students_to_event(live_class, batch)
          live_class.to_frappe_format
        else
          { error: live_class.errors.full_messages.join(", ") }
        end
      else
        { error: zoom_response[:error] }
      end
    end

    def self.get_batch_students(batch, status_filter = nil)
      enrollments = BatchEnrollment.by_batch(batch).includes(:user)

      case status_filter
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

        enrollment.to_frappe_format.merge(
          user_details: {
            email: user.email,
            name: user.full_name,
            username: user.username,
            user_image: user.user_image
          },
          progress: progress,
          certificates: Certificate.where(user: user, batch: batch).published.count,
          last_activity: get_last_activity(user, batch)
        )
      end
    end

    def self.get_batch_statistics(batch)
      enrollments = BatchEnrollment.where(batch: batch)

      {
        total_enrollments: enrollments.count,
        active_enrollments: enrollments.active.count,
        completed_enrollments: enrollments.completed.count,
        payment_statistics: get_payment_statistics(batch),
        progress_statistics: get_progress_statistics(batch),
        completion_rate: calculate_completion_rate(batch),
        dropout_rate: calculate_dropout_rate(batch),
        average_completion_time: calculate_average_completion_time(batch)
      }
    end

    def self.send_batch_start_reminders
      tomorrow = Date.current + 1.day
      batches = Batch.published.where(start_date: tomorrow)

      batches.find_each do |batch|
        batch.batch_enrollments.includes(:user).find_each do |enrollment|
          BatchEnrollmentMailer.start_reminder(enrollment).deliver_later
        end
      end

      batches.count
    end

    def self.send_batch_completion_notifications
      today = Date.current
      batches = Batch.published.where(end_date: today)

      batches.find_each do |batch|
        batch.batch_enrollments.includes(:user).find_each do |enrollment|
          BatchEnrollmentMailer.batch_completed(enrollment).deliver_later
        end
      end

      batches.count
    end

    private

    def self.create_zoom_meeting(zoom_account, params)
      require "net/http"
      require "uri"
      require "json"
      require "base64"

      begin
        # Get Zoom credentials
        credentials = zoom_account.credentials
        return { success: false, error: "Zoom credentials not configured" } unless credentials

        # Get access token using OAuth
        access_token = get_zoom_access_token(credentials)
        return { success: false, error: "Failed to get Zoom access token" } unless access_token

        # Create meeting
        meeting_data = {
          topic: params[:title] || "Live Class",
          type: 2, # Scheduled meeting
          start_time: params[:start_time]&.strftime("%Y-%m-%dT%H:%M:%S"),
          duration: params[:duration] || 60,
          timezone: params[:timezone] || "UTC",
          agenda: params[:description],
          settings: {
            host_video: true,
            participant_video: true,
            join_before_host: zoom_account.enable_join_before_host,
            mute_upon_entry: zoom_account.mute_on_entry,
            watermark: false,
            use_pmi: false,
            approval_type: 0, # Automatically approve
            audio: "both", # Both telephone and computer audio
            auto_recording: zoom_account.auto_record_meetings ? "cloud" : "none",
            waiting_room: zoom_account.enable_waiting_room
          }
        }

        # Make API call to create meeting
        uri = URI.parse("https://api.zoom.us/v2/users/#{credentials[:user_id]}/meetings")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri.request_uri)
        request["Authorization"] = "Bearer #{access_token}"
        request["Content-Type"] = "application/json"
        request.body = meeting_data.to_json

        response = http.request(request)
        meeting = JSON.parse(response.body)

        if response.code.to_i == 201 && meeting["id"]
          {
            success: true,
            start_url: meeting["start_url"],
            join_url: meeting["join_url"],
            meeting_id: meeting["id"].to_s,
            uuid: meeting["uuid"],
            password: meeting["password"]
          }
        else
          { success: false, error: "Zoom API Error: #{meeting['message'] || 'Failed to create meeting'}" }
        end
      rescue JSON::ParserError => e
        { success: false, error: "Invalid JSON response from Zoom: #{e.message}" }
      rescue => e
        { success: false, error: "Unexpected error: #{e.message}" }
      end
    end

    def self.get_zoom_access_token(credentials)
      uri = URI.parse("https://zoom.us/oauth/token")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Authorization"] = "Basic #{Base64.strict_encode64("#{credentials[:api_key]}:#{credentials[:api_secret]}")}"
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request.body = "grant_type=account_credentials&account_id=" + credentials[:account_id]

      response = http.request(request)
      token_data = JSON.parse(response.body)

      if response.code.to_i == 200 && token_data["access_token"]
        token_data["access_token"]
      else
        Rails.logger.error "Zoom OAuth failed: #{token_data['reason'] || token_data['error']}"
        nil
      end
    rescue => e
      Rails.logger.error "Zoom OAuth error: #{e.message}"
      nil
    end

    def self.add_students_to_event(live_class, batch)
      # Create Event Participants for batch students
      batch.batch_enrollments.includes(:user).find_each do |enrollment|
        EventParticipant.find_or_create_by!(
          event: live_class.event,
          reference_doctype: "User",
          reference_docname: enrollment.user.email,
          email: enrollment.user.email
        )
      end
    end

    # Consolidated progress calculation methods
    def self.calculate_user_progress(user, batch)
      calculate_user_progress_for_batch(user, batch)
    end

    def self.get_last_activity(user, batch)
      get_last_activity_for_batch(user, batch)
    end

    def self.get_payment_statistics(batch)
      payments = Payment.where(payable: batch)

      {
        total_revenue: payments.where(status: "Completed").sum(:amount),
        pending_payments: payments.where(status: "Pending").count,
        completed_payments: payments.where(status: "Completed").count,
        refunded_payments: payments.where(status: "Refunded").count,
        average_payment: payments.where(status: "Completed").average(:amount)&.round(2) || 0
      }
    end

    def self.get_progress_statistics(batch)
      enrollments = BatchEnrollment.where(batch: batch)
      user_ids = enrollments.pluck(:user_id)

      {
        average_progress: calculate_average_progress(user_ids, batch),
        completion_rate: calculate_completion_rate(batch),
        active_learners: calculate_active_learners(user_ids, batch),
        dropout_rate: calculate_dropout_rate(batch)
      }
    end

    def self.calculate_average_progress(user_ids, batch)
      return 0 if user_ids.empty?

      total_progress = CourseProgress.joins(:user)
                                     .where(users: { id: user_ids })
                                     .where(course: batch.courses)
                                     .average(:progress) || 0

      total_progress.round(2)
    end

    def self.calculate_completion_rate(batch)
      total_enrollments = BatchEnrollment.where(batch: batch).count
      return 0 if total_enrollments == 0

      completed_enrollments = BatchEnrollment.joins(:batch)
                                             .where(batches: { id: batch.id, end_date: ...Date.current })
                                             .count

      (completed_enrollments.to_f / total_enrollments * 100).round(2)
    end

    def self.calculate_dropout_rate(batch)
      total_enrollments = BatchEnrollment.where(batch: batch).count
      return 0 if total_enrollments == 0

      # Define dropout as enrollment without any progress after 30 days
      cutoff_date = 30.days.ago
      dropouts = BatchEnrollment.joins(:user)
                                .where(batch: batch)
                                .where("batch_enrollments.created_at < ?", cutoff_date)
                                .left_joins(:course_progresses)
                                .where(course_progresses: { id: nil })
                                .count

      (dropouts.to_f / total_enrollments * 100).round(2)
    end

    def self.calculate_active_learners(user_ids, batch)
      return 0 if user_ids.empty?

      # Active learners are those with progress in the last 7 days
      active_cutoff = 7.days.ago
      CourseProgress.joins(:user)
                    .where(users: { id: user_ids })
                    .where(course: batch.courses)
                    .where("course_progresses.updated_at > ?", active_cutoff)
                    .distinct
                    .count
    end

    def self.calculate_average_completion_time(batch)
      completed_enrollments = BatchEnrollment.joins(:batch)
                                             .where(batches: { id: batch.id, end_date: ...Date.current })
                                             .includes(:user)

      return 0 if completed_enrollments.empty?

      completion_times = completed_enrollments.map do |enrollment|
        # Calculate time from enrollment to batch completion
        enrollment_date = enrollment.created_at.to_date
        completion_date = enrollment.batch.end_date
        (completion_date - enrollment_date).to_i
      end

      (completion_times.sum.to_f / completion_times.length).round(2)
    end
  end
end
