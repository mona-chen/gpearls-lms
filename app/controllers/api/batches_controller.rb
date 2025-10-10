class Api::BatchesController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    filters = params.permit(:enrolled, :start_date, :category).to_h
    batches = Batch.all

    if filters['enrolled'] && current_user
      enrolled_batch_ids = current_user.batch_enrollments.pluck(:batch_id)
      batches = batches.where(id: enrolled_batch_ids)
    end

    if filters['start_date']
      if filters['start_date'].start_with?('>')
        batches = batches.where('start_date > ?', Date.today)
      elsif filters['start_date'].start_with?('<')
        batches = batches.where('start_date < ?', Date.today)
      end
    end

    if filters['category'].present?
      batches = batches.where(category: filters['category'])
    end

    batches = batches.where(published: true) unless current_user
    batches = batches.order(start_date: :desc).limit(30)

    render json: batches.map { |batch| format_batch(batch) }
  end

  def show
    batch = Batch.find(params[:batch])
    return render json: { error: 'Batch not found' }, status: :not_found unless batch

    unless batch.published || (current_user && current_user.batch_enrollments.exists?(batch: batch))
      return render json: { error: 'Unauthorized' }, status: :forbidden
    end

    render json: format_batch_detail(batch)
  end

  def enroll
    batch = Batch.find(params[:batch])
    return render json: { error: 'Batch not found' }, status: :not_found unless batch

    # Check if already enrolled
    if current_user.batch_enrollments.exists?(batch: batch)
      return render json: { error: 'Already enrolled' }, status: :conflict
    end

    # Check seat availability
    if batch.seat_count && batch.batch_enrollments.count >= batch.seat_count
      return render json: { error: 'Batch is full' }, status: :conflict
    end

    # Check if batch has started
    if batch.start_date && batch.start_date < Date.today
      return render json: { error: 'Batch has already started' }, status: :conflict
    end

    enrollment = BatchEnrollment.new(
      batch: batch,
      user: current_user,
      source: params[:source] || 'Website'
    )

    if enrollment.save
      render json: { success: true, enrollment_id: enrollment.id }
    else
      render json: { error: enrollment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def format_batch(batch)
    {
      name: batch.id,
      title: batch.title,
      description: batch.description,
      start_date: batch.start_date,
      end_date: batch.end_date,
      start_time: batch.start_time,
      end_time: batch.end_time,
      timezone: batch.timezone,
      published: batch.published,
      category: batch.category,
      paid_batch: batch.paid_batch,
      amount: batch.amount,
      currency: batch.currency,
      seat_count: batch.seat_count,
      seats_left: batch.seat_count ? batch.seat_count - batch.batch_enrollments.count : nil,
      instructors: batch.instructor ? [format_instructor(batch.instructor)] : []
    }
  end

  def format_batch_detail(batch)
    format_batch(batch).merge(
      batch_details: batch.batch_details,
      batch_details_raw: batch.batch_details_raw,
      evaluation_end_date: batch.evaluation_end_date,
      allow_self_enrollment: batch.allow_self_enrollment,
      certification: batch.certification,
      zoom_account: batch.zoom_account,
      courses: batch.batch_courses.map do |bc|
        {
          course: bc.course_id,
          title: bc.title,
          evaluator: bc.evaluator
        }
      end,
      students: batch.batch_enrollments.count,
      accept_enrollments: batch.start_date.nil? || batch.start_date >= Date.today
    )
  end

  def format_instructor(user)
    {
      name: user.id,
      username: user.username,
      full_name: user.full_name,
      user_image: user.user_image,
      first_name: user.first_name
    }
  end
end