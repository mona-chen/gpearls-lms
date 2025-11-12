module Batches
  class BatchesService
    def self.call(params = {})
      new(params).call
    end

    def initialize(params = {})
      @params = params
    end

    def call
      batches = Batch.includes(:instructor, :batch_courses, :courses)

      # Apply filters from request
      if @params[:filters].present?
        filters = @params[:filters].to_unsafe_h
        if filters["start_date"]
          start_date = filters["start_date"].first == ">=" ? Date.today : filters["start_date"].first
          batches = batches.where("start_date >= ?", start_date)
        end
        batches = batches.where(published: true) if filters["published"] == 1
      end

      # Apply ordering
      if @params[:order_by].present?
        batches = batches.order(@params[:order_by])
      else
        batches = batches.order(start_date: :desc)
      end

      # Apply pagination
      limit = @params[:limit] || 20
      offset = @params[:start] || 0
      batches = batches.limit(limit).offset(offset)

      batches_data = batches.map do |batch|
        # Frappe-compatible format matching lms/utils.py get_batches
        {
          name: batch.name,
          title: batch.title,
          batch_id: batch.id,
          course_id: batch.courses.first&.id, # Primary course
          course_title: batch.courses.first&.title, # Primary course title
          start_date: batch.start_date&.strftime("%Y-%m-%d"),
          end_date: batch.end_date&.strftime("%Y-%m-%d"),
          start_time: batch.start_time,
          end_time: batch.end_time,
          timezone: batch.timezone,
          description: batch.description,
          batch_details: batch.additional_info,
          published: batch.published,
          allow_self_enrollment: batch.allow_self_enrollment,
          certification: batch.certification,
          seat_count: batch.seat_count,
          evaluation_end_date: batch.evaluation_end_date&.strftime("%Y-%m-%d"),
          medium: batch.medium,
          category: batch.category,
          confirmation_email_template: batch.confirmation_email_template,
          instructors: batch.instructors_list,
          zoom_account: batch.zoom_account,
          paid_batch: batch.paid_batch,
          amount: batch.amount,
          currency: batch.currency,
          amount_usd: batch.amount_usd,
          show_live_class: batch.show_live_class,
          allow_future: batch.allow_future,
          status: batch.status,
          current_seats: batch.current_seats,
          seats_left: batch.seats_left,
          full: batch.full?,
          accept_enrollments: batch.accept_enrollments?,
          courses: batch.batch_courses.map(&:to_frappe_format),
          creation: batch.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
          modified: batch.updated_at&.strftime("%Y-%m-%d %H:%M:%S"),
          owner: batch.instructor&.email
        }
      end

      { "data" => batches_data }
    end

    # NEW: Get batches created by a specific user (instructor)
    def self.get_created_batches(user)
      return { error: "User not authenticated" } unless user

      batches = Batch.where(instructor: user)
                     .includes(:instructor, :batch_courses, :courses)
                     .order(created_at: :desc)

      batches_data = batches.map do |batch|
        {
          name: batch.name,
          title: batch.title,
          batch_id: batch.id,
          course_id: batch.courses.first&.id, # Primary course
          course_title: batch.courses.first&.title, # Primary course title
          start_date: batch.start_date&.strftime("%Y-%m-%d"),
          end_date: batch.end_date&.strftime("%Y-%m-%d"),
          start_time: batch.start_time,
          end_time: batch.end_time,
          timezone: batch.timezone,
          description: batch.description,
          batch_details: batch.additional_info,
          published: batch.published,
          allow_self_enrollment: batch.allow_self_enrollment,
          certification: batch.certification,
          seat_count: batch.seat_count,
          evaluation_end_date: batch.evaluation_end_date&.strftime("%Y-%m-%d"),
          medium: batch.medium,
          category: batch.category,
          confirmation_email_template: batch.confirmation_email_template,
          instructors: batch.instructors_list,
          zoom_account: batch.zoom_account,
          paid_batch: batch.paid_batch,
          amount: batch.amount,
          currency: batch.currency,
          amount_usd: batch.amount_usd,
          show_live_class: batch.show_live_class,
          allow_future: batch.allow_future,
          status: batch.status,
          current_seats: batch.current_seats,
          seats_left: batch.seats_left,
          full: batch.full?,
          accept_enrollments: batch.accept_enrollments?,
          courses: batch.batch_courses.map(&:to_frappe_format),
          creation: batch.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
          modified: batch.updated_at&.strftime("%Y-%m-%d %H:%M:%S"),
          owner: batch.instructor&.email
        }
      end

      {
        success: true,
        batches: batches_data,
        total: batches_data.count,
        message: "Retrieved #{batches_data.count} batches created by #{user.full_name}"
      }
    end
  end
end
