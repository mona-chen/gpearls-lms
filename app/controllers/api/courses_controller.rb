class Api::CoursesController < Api::BaseController
  skip_before_action :authenticate_user!, only: [ :index, :show, :create ]

  def index
    filters = filter_params.slice(:enrolled, :created, :certification, :title)
    pagination = pagination_params
    courses = Course.includes(:instructor)

    # Apply filters
    if filters[:enrolled] && current_user
      enrolled_course_ids = current_user.enrollments.pluck(:course_id)
      courses = courses.where(id: enrolled_course_ids)
    end

    if filters[:created] && current_user
      courses = courses.where(instructor: current_user)
    end

    if filters[:certification]
      courses = courses.where(enable_certification: true)
    end

    if filters[:title]
      courses = courses.where("title ILIKE ?", "%#{filters[:title]}%")
    end

    # Only show published courses for non-authenticated users
    courses = courses.where(published: true) unless current_user

    courses = courses.order(enrollments_count: :desc)
                     .page(pagination[:page])
                     .per(pagination[:per_page] || 30)

    render json: courses.map { |course| format_course(course) }
  end

  def show
    course = Course.find(params[:course])
    return render json: { error: "Course not found" }, status: :not_found unless course

    # Check if user can access this course
    unless course.published || (current_user && (current_user.instructor? || course.instructor == current_user))
      return render json: { error: "Unauthorized" }, status: :forbidden
    end

    render json: format_course_detail(course)
  end

  def create
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
    Permissions::PermissionsService.authorize!(current_user, :edit_course, Course, course)

    if course.update(course_params)
      render json: format_course(course)
    else
      render json: { error: course.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    course = Course.find(params[:course])
    Permissions::PermissionsService.authorize!(current_user, :delete_course, Course, course)

    course.destroy
    render json: { message: "Course deleted" }
  end

  def enroll
    course = Course.find(params[:id])
    return render json: { error: "Course not found" }, status: :not_found unless course

    enrollment = Enrollment.find_or_create_by!(user: current_user, course: course)
    render json: { message: "Successfully enrolled in #{course.title}" }
  end

  def progress
    course = Course.find(params[:id])
    return render json: { error: "Course not found" }, status: :not_found unless course

    enrollment = current_user.enrollments.find_by(course: course)
    return render json: { error: "Not enrolled" }, status: :forbidden unless enrollment

    progress = CourseProgressService.new(current_user, course).calculate_progress
    render json: progress
  end

  def create_chapter
    course = Course.find(params[:id])
    Permissions::PermissionsService.authorize!(current_user, :edit_course, Course, course)

    chapter = course.chapters.create!(chapter_params)
    render json: { id: chapter.id, title: chapter.title }, status: :created
  end

  def create_lesson
    course = Course.find(params[:course_id])
    chapter = course.chapters.find(params[:chapter_id])
    Permissions::PermissionsService.authorize!(current_user, :edit_course, Course, course)

    lesson = chapter.lessons.create!(lesson_params)
    render json: { id: lesson.id, title: lesson.title }, status: :created
  end

  private

  def course_params
    params.require(:course).permit(:title, :description, :short_introduction, :video_link, :image,
                  :tags, :category, :published, :featured, :paid_course,
                  :enable_certification, :paid_certificate, :course_price, :currency)
  end

  def chapter_params
    params.require(:chapter).permit(:title, :description)
  end

  def lesson_params
    params.require(:lesson).permit(:title, :content)
  end

  def can_edit_course?(course)
    current_user && (current_user.moderator? || course.instructor == current_user)
  end

  def format_course(course)
    {
      name: course.id,
      title: course.title,
      tags: course.tags&.split(",") || [],
      image: course.image,
      card_gradient: course.card_gradient,
      short_introduction: course.short_introduction,
      published: course.published,
      upcoming: course.upcoming?,
      featured: course.featured,
      category: course.category,
      status: course.published ? "Approved" : "Under Review",
      paid_course: course.price.present? && course.price > 0,
      paid_certificate: false, # Not implemented yet
      course_price: course.price,
      currency: course.currency,
      enable_certification: course.certificate_enabled,
      lessons: course.enrollments_count, # Using enrollments_count as lessons for now
      enrollments: course.enrollments_count,
      rating: course.rating,
      instructors: course.instructor ? [ format_instructor(course.instructor) ] : []
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
