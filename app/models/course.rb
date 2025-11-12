class Course < ApplicationRecord
  self.table_name = "lms_courses"

  # Database column aliases (Frappe compatibility)
  alias_attribute :course_price, :price

# Associations
belongs_to :instructor, class_name: "User", optional: true
belongs_to :evaluator, class_name: "User", optional: true

  has_many :chapters, -> { order(:idx) }, class_name: "CourseChapter", foreign_key: "course", primary_key: "id", dependent: :destroy
   has_many :lessons, -> { order(:idx) }, through: :chapters, class_name: "CourseLesson", dependent: :destroy
   has_many :enrollments, dependent: :destroy
    has_many :course_progresses, ->(course) { where(course: course.name) }, class_name: "CourseProgress", dependent: :destroy
  has_many :quizzes, dependent: :destroy
   has_many :course_reviews, ->(course) { where(course: course.name) }, class_name: "CourseReview", dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :short_introduction, presence: true
   validates :status, inclusion: { in: %w[Draft In Progress Under Review Approved] }, allow_blank: true
  validates :course_price, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :currency, inclusion: { in: Currency::ConversionService.supported_currencies }, allow_blank: true

  # Callbacks
  before_save :set_published_at, if: :will_save_change_to_published?
  before_save :set_default_currency, if: :new_record?
  before_save :set_status_from_published, if: :published_changed?
  before_save :set_default_workflow_state, if: :new_record?

  # Scopes
  scope :published, -> { where(published: true) }
  scope :upcoming, -> { where(upcoming: true) }
  scope :featured, -> { where(featured: true) }
  scope :paid, -> { where.not(course_price: nil).where("course_price > 0") }
  scope :free, -> { where(course_price: [ nil, 0 ]) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_category, ->(category) { where(category: category) }
  scope :enrollable, -> { published.where(upcoming: false) }

  # Class Methods
  def self.available_for_enrollment(user)
    published.where.not(paid: true).or(
      paid.where.not(enrollments: { user: user }))
  end

  def self.featured_courses(limit = 10)
    published.featured.limit(limit)
  end

  def self.search_by_tag(tag)
    where("tags LIKE ?", "%#{tag}%")
  end

  # Instance Methods
  def published?
    published == true
  end

  def upcoming?
    upcoming == true
  end

  def featured?
    featured == true
  end

  def paid?
    course_price.present? && course_price > 0
  end

  def paid_course
    paid?
  end

  def paid_certificate
    false # Not implemented yet - could be a separate paid certificate feature
  end

  def enable_certification
    certificate_enabled
  end

  def free?
    !paid?
  end

  def disable_self_learning?
    !allow_self_enrollment
  end

  def disable_self_learning
    !allow_self_enrollment
  end

  def has_instructors?
    instructors.present?
  end

  def can_be_enrolled_by?(user)
    published? && (!paid? || !enrollments.exists?(user: user))
  end

  def average_rating
    CourseReview.average_rating_for(self)
  end

  def total_reviews
    CourseReview.total_reviews_for(self)
  end

  def rating_distribution
    CourseReview.rating_distribution_for(self)
  end

  def total_lessons
    lessons.count
  end

  def total_chapters
    chapters.count
  end

  def enrollment_count
    enrollments.count
  end

  def completion_rate
    return 0 if enrollment_count == 0
    completed_enrollments = course_progresses.where(status: "Completed").count
    (completed_enrollments.to_f / enrollment_count * 100).round(2)
  end

  def price_in_currency(currency_code)
    return course_price unless paid?

    # Currency conversion logic would go here
    # This would integrate with a currency service
    course_price
  end

  def amount_usd
    return 0 unless paid? && course_price.present?
    Currency::ConversionService.convert_to_usd(course_price, currency || default_currency)
  end

  def default_currency
    Currency::ConversionService.default_currency
  end

  def name
    # In Frappe, name is a slug-based unique identifier
    # We'll use the title as a base for now
    title&.parameterize&.downcase || id.to_s
  end

  def instructors
    # Return array of instructor names to match Frappe format
    return [] unless instructor
    [ instructor.full_name || instructor.username || instructor.email ]
  end

  def price_in_currency(target_currency = nil)
    return course_price unless paid? && course_price.present?
    return course_price unless target_currency && target_currency != currency

    Currency::ConversionService.convert(
      course_price,
      currency || default_currency,
      target_currency
    )
  end

  def to_frappe_format
    {
      "name" => id,
      "title" => title,
      "tags" => tags,
      "description" => description,
      "image" => image,
      "video_link" => video_link,
      "short_introduction" => short_introduction,
      "published" => published,
      "upcoming" => upcoming,
      "featured" => featured,
      "disable_self_learning" => disable_self_learning || false,
      "published_on" => published_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "category" => category,
      "status" => status,
      "paid_course" => paid_course || false,
      "paid_certificate" => false, # Not implemented yet
      "course_price" => course_price,
      "currency" => currency,
      "amount_usd" => amount_usd,
      "enable_certification" => certificate_enabled || false,
      "lessons" => total_lessons,
      "enrollments" => enrollment_count,
      "rating" => average_rating,
      "card_gradient" => nil, # Not implemented yet
      "instructors" => instructors,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "owner" => instructor&.email,
      "instructor" => instructor&.full_name,
      "instructor_id" => instructor&.id
    }
  end

  # Frappe-compatible enrollment count formatting
  def enrollment_count_formatted
    if enrollment_count >= 1000
      "#{(enrollment_count / 1000.0).round(1)}k"
    else
      enrollment_count.to_s
    end
  end

  def card_gradient
    # Default gradient for course cards - can be customized later
    "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"
  end

  # Membership data for enrolled users
  def membership_for(user)
    return nil unless user

    enrollment = enrollments.find_by(user: user)
    return nil unless enrollment

    progress_percentage = enrollment.progress || 0

    {
      "enrollment_date" => enrollment.created_at.strftime("%Y-%m-%d"),
      "progress" => progress_percentage,
      "completed" => enrollment.completed?,
      "completion_date" => enrollment.completed? ? enrollment.updated_at.strftime("%Y-%m-%d") : nil
    }
  end

  # Current lesson for user (for continue learning functionality)
  def current_lesson_for(user)
    return nil unless user

    # Find the last accessed lesson or first incomplete lesson
    lesson_progress = course_progresses.where(member: user.id).order(updated_at: :desc).first
    return nil unless lesson_progress

    # Get the lesson and chapter information
    lesson = CourseLesson.find_by(name: lesson_progress.lesson)
    return nil unless lesson

    chapter = lesson.chapter
    return nil unless chapter

    "#{chapter.idx}-#{lesson.idx || 1}"
  end

  # Workflow methods
  def workflow
    @workflow ||= Workflow.find_by(document_type: "Course", is_active: true)
  end

  def can_transition_to?(new_state, user)
    return false unless workflow

    transition = workflow.workflow_transitions.find_by(state: workflow_state, next_state: new_state)
    return false unless transition

    # Check if user has required role
    allowed_roles = transition.allowed_roles&.split(",")&.map(&:strip) || []
    return true if allowed_roles.empty?

    user_roles = user.roles || []
    (allowed_roles & user_roles).any?
  end

  def transition_to(new_state, user)
    return false unless can_transition_to?(new_state, user)

    update(workflow_state: new_state)
  end

  private

  def set_published_at
    self.published_at = Time.current if published? && published_at.blank?
  end



  def set_default_currency
    self.currency ||= default_currency if paid?
  end

  def set_status_from_published
    if published? && (status.blank? || status.strip == "In Progress")
      self.status = "Approved"
    end
  end

  def set_default_workflow_state
    self.workflow_state ||= "Draft"
  end
end
