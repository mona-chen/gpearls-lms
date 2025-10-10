class Api::CoursesController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    filters = params.permit(:enrolled, :created, :certification, :title).to_h
    courses = Course.all

    # Apply filters
    if filters['enrolled'] && current_user
      enrolled_course_ids = current_user.enrollments.pluck(:course_id)
      courses = courses.where(id: enrolled_course_ids)
    end

    if filters['created'] && current_user
      courses = courses.where(instructor: current_user)
    end

    if filters['certification']
      courses = courses.where(enable_certification: true)
    end

    if filters['title']
      courses = courses.where('title LIKE ?', "%#{filters['title']}%")
    end

    # Only show published courses for non-authenticated users
    courses = courses.where(published: true) unless current_user

    courses = courses.order(enrollments_count: :desc).limit(30)

    render json: courses.map { |course| format_course(course) }
  end

  def show
    course = Course.find(params[:course])
    return render json: { error: 'Course not found' }, status: :not_found unless course

    # Check if user can access this course
    unless course.published || (current_user && (current_user.instructor? || course.instructor == current_user))
      return render json: { error: 'Unauthorized' }, status: :forbidden
    end

    render json: format_course_detail(course)
  end

  def create
    return render json: { error: 'Unauthorized' }, status: :forbidden unless current_user&.instructor?

    course = Course.new(course_params)
    course.instructor = current_user

    if course.save
      render json: format_course(course), status: :created
    else
      render json: { error: course.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    course = Course.find(params[:course])
    return render json: { error: 'Unauthorized' }, status: :forbidden unless can_edit_course?(course)

    if course.update(course_params)
      render json: format_course(course)
    else
      render json: { error: course.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    course = Course.find(params[:course])
    return render json: { error: 'Unauthorized' }, status: :forbidden unless can_edit_course?(course)

    course.destroy
    render json: { message: 'Course deleted' }
  end

  private

  def course_params
    params.permit(:title, :description, :short_introduction, :video_link, :image,
                  :tags, :category, :published, :featured, :paid_course,
                  :enable_certification, :paid_certificate, :course_price, :currency)
  end

  def can_edit_course?(course)
    current_user && (current_user.moderator? || course.instructor == current_user)
  end

  def format_course(course)
    {
      name: course.id,
      title: course.title,
      tags: course.tags&.split(',') || [],
      image: course.image,
      card_gradient: course.card_gradient,
      short_introduction: course.short_introduction,
      published: course.published,
      upcoming: course.upcoming,
      featured: course.featured,
      category: course.category,
      status: course.published ? 'Approved' : 'Under Review',
      paid_course: course.paid_course,
      paid_certificate: course.paid_certificate,
      course_price: course.course_price,
      currency: course.currency,
      enable_certification: course.enable_certification,
      lessons: course.lessons_count,
      enrollments: course.enrollments_count,
      rating: course.rating,
      instructors: course.instructor ? [format_instructor(course.instructor)] : []
    }
  end

  def format_course_detail(course)
    format_course(course).merge(
      description: course.description,
      video_link: course.video_link,
      published_on: course.published_on,
      amount_usd: course.amount_usd,
      membership: current_user ? current_user.enrollments.find_by(course: course)&.as_json : nil
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