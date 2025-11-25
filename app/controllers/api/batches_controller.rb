class Api::BatchesController < Api::BaseController
  before_action :authenticate_user!, except: [ :index, :show, :create ]
  before_action :set_batch, only: [ :show, :update, :destroy, :enroll, :unenroll, :timetable, :students, :statistics ]
  before_action :require_batch_instructor_or_admin!, only: [ :update, :destroy, :students, :statistics ]

  # GET /api/batches
  def index
    filters = filter_params.slice(:category, :my_batches, :starting_soon, :status, :paid)
    search = search_params[:search]
    pagination = pagination_params

    batches = Batch.includes(:instructor, :batch_courses, :courses)
                  .published
                  .order(start_date: :asc)

    # Apply filters
    batches = batches.by_category(filters[:category]) if filters[:category].present?
    batches = batches.by_instructor(current_user) if filters[:my_batches] == "true"
    batches = batches.starting_soon if filters[:starting_soon] == "true"
    batches = batches.active if filters[:status] == "active"
    batches = batches.upcoming if filters[:status] == "upcoming"
    batches = batches.completed if filters[:status] == "completed"
    batches = batches.paid if filters[:paid] == "true"
    batches = batches.free if filters[:paid] == "false"

    # Apply search
    if search.present?
      search_term = "%#{search.gsub('%', '\\%').gsub('_', '\\_')}%"
      batches = batches.where("batches.title ILIKE ?", search_term)
    end

    # Pagination
    page = pagination[:page] || 1
    per_page = pagination[:per_page] || 20
    batches = batches.page(page).per(per_page)

    render json: {
      data: batches.map(&:to_frappe_format),
      pagination: {
        current_page: page.to_i,
        per_page: per_page.to_i,
        total_count: Batch.published.count
      }
    }
  end

  # GET /api/batches/:id
  def show
    render json: @batch.to_frappe_format
  end

  # POST /api/batches
  def create
    batch = Batch.new(batch_params.except(:course_id, :instructor_id).merge(
      start_time: batch_params[:start_time] || "09:00",
      end_time: batch_params[:end_time] || "17:00",
      additional_info: batch_params[:additional_info] || "Additional information",
      max_students: batch_params[:max_students] || batch_params[:seat_count] || 50
    ))
    batch.instructor = current_user

    if batch.save
      # Add instructor to instructors list if not already present
      batch.add_instructor(current_user) unless batch.has_instructor?(current_user)

      # Add course if provided
      if batch_params[:course_id].present?
        course = Course.find(batch_params[:course_id])
        batch.batch_courses.create!(course: course)
      end

      render json: batch.to_frappe_format, status: :created
    else
      render json: { errors: batch.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/batches/:id
  def update
    if @batch.update(batch_params)
      render json: @batch.to_frappe_format
    else
      render json: { errors: @batch.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/batches/:id
  def destroy
    ActiveRecord::Base.transaction do
      # Send cancellation notifications
      @batch.batch_enrollments.includes(:user).find_each do |enrollment|
        BatchEnrollmentMailer.batch_cancelled(enrollment, "Batch deleted by instructor").deliver_later
      end

      @batch.destroy
    end

    render json: { message: "Batch deleted successfully" }
  end

  # POST /api/batches/:id/enroll
  def enroll
    # Check if batch allows self-enrollment
    unless @batch.allow_self_enrollment && @batch.published
      return render json: { error: "Batch does not allow self-enrollment" }, status: :forbidden
    end

    # Handle payment for paid batches
    payment = nil
    if @batch.paid_batch
      payment_params = params.require(:payment).permit(:amount, :currency, :payment_method)
      payment = Payment.create!(
        payable: @batch,
        user: current_user,
        amount: payment_params[:amount] || @batch.amount,
        currency: payment_params[:currency] || @batch.currency,
        status: "Pending",
        payment_method: payment_params[:payment_method]
      )
    end

    # Get source if provided
    source = Source.find_by(name: params[:source]) if params[:source].present?

    result = Batches::BatchEnrollmentService.enroll_user(
      @batch,
      current_user,
      payment: payment,
      source: source
    )

    if result[:success]
      render json: result[:data].to_frappe_format, status: :created
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  # DELETE /api/batches/:id/unenroll
  def unenroll
    enrollment = BatchEnrollment.find_by(batch: @batch, user: current_user)
    return render json: { error: "Not enrolled in this batch" }, status: :not_found unless enrollment

    reason = params[:reason] || "User requested unenrollment"
    result = Batches::BatchEnrollmentService.cancel_enrollment(enrollment, reason)

    if result[:success]
      render json: { message: result[:message] }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  # GET /api/batches/:id/timetable
  def timetable
    start_date = params[:start_date]&.to_date
    end_date = params[:end_date]&.to_date

    timetable = @batch.get_timetable(start_date: start_date, end_date: end_date)

    render json: {
      data: timetable.map do |entry|
        if entry.is_a?(LiveClass)
          {
            name: entry.name,
            title: entry.title,
            date: entry.date.strftime("%Y-%m-%d"),
            start_time: entry.time.strftime("%H:%M:%S"),
            end_time: (entry.time + entry.duration.minutes).strftime("%H:%M:%S"),
            reference_doctype: "LMS Live Class",
            reference_docname: entry.name,
            url: entry.join_url,
            duration: entry.duration,
            milestone: false
          }
        else
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
      end
    }
  end

  # GET /api/batches/:id/students
  def students
    status_filter = params[:status]
    enrollments = Batches::BatchEnrollmentService.get_batch_enrollments(@batch, status_filter)

    render json: {
      data: enrollments.map do |enrollment|
        user = enrollment.user
        progress = Batches::BatchService.calculate_user_progress_for_batch(user, @batch)

        enrollment.to_frappe_format.merge(
          user_details: {
            email: user.email,
            name: user.full_name,
            username: user.username,
            user_image: user.user_image
          },
          progress: progress,
          certificates: Certificate.where(user: user, batch: @batch).published.count,
          last_activity: get_last_activity(user, @batch)
        )
      end
    }
  end

  # GET /api/batches/:id/statistics
  def statistics
    stats = @batch.enrollment_statistics.merge(@batch.progress_statistics)

    render json: {
      batch_info: {
        title: @batch.title,
        status: @batch.status,
        start_date: @batch.start_date.strftime("%Y-%m-%d"),
        end_date: @batch.end_date.strftime("%Y-%m-%d"),
        total_seats: @batch.seat_count,
        seats_filled: @batch.current_seats,
        seats_available: @batch.seats_left
      },
      enrollment_statistics: stats[:enrollment_statistics],
      progress_statistics: stats[:progress_statistics],
      payment_statistics: get_payment_statistics(@batch),
      course_statistics: get_course_statistics(@batch),
      time_statistics: get_time_statistics(@batch)
    }
  end

  # POST /api/batches/:id/add-timetable-entry
  def add_timetable_entry
    entry_params = params.require(:timetable_entry).permit(
      :reference_doctype,
      :reference_docname,
      :date,
      :start_time,
      :end_time,
      :milestone
    )

    entry = @batch.add_timetable_entry(
      entry_params[:reference_doctype],
      entry_params[:reference_docname],
      entry_params[:date].to_date,
      entry_params[:start_time],
      entry_params[:end_time],
      milestone: entry_params[:milestone] || false
    )

    render json: entry.to_frappe_format, status: :created
  end

  # POST /api/batches/:id/create-live-class
  def create_live_class
    live_class_params = params.require(:live_class).permit(
      :title,
      :date,
      :time,
      :duration,
      :description,
      :auto_recording
    )

    live_class = @batch.create_live_class(live_class_params)

    render json: live_class.to_frappe_format, status: :created
  end

  # POST /api/batches/:id/add-assessment
  def add_assessment
    assessment_params = params.require(:assessment).permit(
      :assessment_type,
      :assessment_name,
      :due_date,
      :max_marks
    )

    assessment = @batch.add_assessment(
      assessment_params[:assessment_type],
      assessment_params[:assessment_name],
      due_date: assessment_params[:due_date]&.to_date,
      max_marks: assessment_params[:max_marks] || 100
    )

    render json: assessment.to_frappe_format, status: :created
  end

  # GET /api/batches/my-enrollments
  def my_enrollments
    status_filter = params[:status]
    enrollments = Batches::BatchEnrollmentService.get_user_enrollments(current_user, status_filter)

    render json: {
      data: enrollments.map do |enrollment|
        enrollment.to_frappe_format.merge(
          batch_details: enrollment.batch.to_frappe_format,
          progress: Batches::BatchService.calculate_user_progress_for_batch(current_user, enrollment.batch),
          upcoming_events: enrollment.batch.live_classes
                                       .where("date >= ?", Date.current)
                                       .order(:date, :time)
                                       .limit(3)
                                       .map(&:to_frappe_format),
          pending_assessments: enrollment.batch.pending_assessments_for(current_user)
                                       .map(&:to_frappe_format)
        )
      end
    }
  end

  # POST /api/batches/:id/issue-certificate
  def issue_certificate
    return render json: { error: "Batch does not issue certificates" } unless @batch.certification

    template = params[:template] || "default"
    certificate = @batch.issue_certificate(current_user, template: template)

    if certificate
      render json: certificate.to_frappe_format
    else
      render json: { error: "Unable to issue certificate" }, status: :unprocessable_entity
    end
  end

  private

  def set_batch
    @batch = Batch.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Batch not found" }, status: :not_found
  end

  def batch_params
    params.require(:batch).permit(
      :title,
      :description,
      :batch_details,
      :additional_info,
      :start_date,
      :end_date,
      :start_time,
      :end_time,
      :timezone,
      :published,
      :allow_self_enrollment,
      :certification,
      :seat_count,
      :evaluation_end_date,
      :medium,
      :category,
      :confirmation_email_template,
      :instructors,
      :zoom_account,
      :paid_batch,
      :amount,
      :currency,
      :amount_usd,
      :show_live_class,
      :allow_future,
      :timetable_template,
      :custom_component,
      :custom_script,
      :meta_image,
      :course_id,
      :instructor_id,
      batch_courses_attributes: [ :id, :course_id, :evaluator_id, :_destroy ]
    )
  end

  def require_batch_instructor_or_admin!
    return true if @batch.instructor == current_user
    return true if @batch.has_instructor?(current_user)
    return true if current_user.has_role?("System Manager") || current_user.has_role?("Administrator")

    render json: { error: "Unauthorized" }, status: :forbidden
  end

  def calculate_user_progress(user, batch)
    Batches::BatchService.calculate_user_progress_for_batch(user, batch)
  end

  def get_last_activity(user, batch)
    Batches::BatchService.get_last_activity_for_batch(user, batch)
  end

  def get_payment_statistics(batch)
    payments = Payment.where(payable: batch)

    {
      total_revenue: payments.where(status: "Completed").sum(:amount),
      pending_payments: payments.where(status: "Pending").count,
      completed_payments: payments.where(status: "Completed").count,
      refunded_payments: payments.where(status: "Refunded").count,
      average_payment: payments.where(status: "Completed").average(:amount)&.round(2) || 0
    }
  end

  def get_course_statistics(batch)
    courses_stats = batch.batch_courses.includes(:course).map do |batch_course|
      course = batch_course.course
      enrollments = batch.batch_enrollments.joins(:user)
                               .joins("LEFT JOIN course_progresses ON course_progresses.user_id = users.id")
                               .where("course_progresses.course = ?", course.id)

      {
        course: course.to_frappe_format,
        enrolled_count: enrollments.count,
        average_progress: enrollments.average("course_progresses.progress")&.round(2) || 0,
        completion_count: enrollments.where("course_progresses.status = ?", "Completed").count
      }
    end

    {
      courses: courses_stats,
      total_courses: batch.courses.count,
      average_course_progress: courses_stats.empty? ? 0 : (courses_stats.pluck(:average_progress).sum / courses_stats.length).round(2)
    }
  end

  def get_time_statistics(batch)
    current_time = Time.current
    start_datetime = batch.start_date.to_datetime + batch.start_time.seconds_since_midnight.seconds
    end_datetime = batch.end_date.to_datetime + batch.end_time.seconds_since_midnight.seconds

    {
      start_datetime: start_datetime.strftime("%Y-%m-%d %H:%M:%S %Z"),
      end_datetime: end_datetime.strftime("%Y-%m-%d %H:%M:%S %Z"),
      duration_days: batch.duration_days,
      duration_hours: ((end_datetime - start_datetime) / 1.hour).round(2),
      time_until_start: start_datetime > current_time ? ((start_datetime - current_time) / 1.day).round(1) : 0,
      time_until_end: end_datetime > current_time ? ((end_datetime - current_time) / 1.day).round(1) : 0,
      timezone: batch.timezone
    }
  end
end
