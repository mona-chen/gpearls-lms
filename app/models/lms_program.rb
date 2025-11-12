class LmsProgram < ApplicationRecord
  # Associations
  has_many :lms_program_members, dependent: :destroy
  has_many :users, through: :lms_program_members
  has_many :lms_program_courses, dependent: :destroy
  has_many :courses, through: :lms_program_courses

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :title, presence: true

  # Callbacks
  before_save :update_counts
  after_create :update_name_from_title

  # Scopes
  scope :published, -> { where(published: true) }
  scope :featured, -> { where(featured: true) }

  # Instance methods
  def published?
    published
  end

  def featured?
    featured
  end

  def enrolled_users
    lms_program_members.includes(:user).map(&:user)
  end

  def user_progress(user)
    member = lms_program_members.find_by(user: user)
    member&.progress || 0.0
  end

  def enroll_user(user)
    return false if enrolled_users.include?(user)

    lms_program_members.create!(
      user: user,
      progress: 0.0,
      creation: Time.current,
      modified: Time.current
    )

    update_counts
    true
  end

  # Public method for updating counts
  def update_counts
    self.course_count = lms_program_courses.count
    self.member_count = lms_program_members.count
    self.modified = Time.current
  end

  # Frappe compatibility methods
  def to_frappe_format
    {
      name: name,
      title: title,
      description: description,
      published: published,
      featured: featured,
      course_count: course_count || 0,
      member_count: member_count || 0,
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: modified&.strftime("%Y-%m-%d %H:%M:%S"),
      owner: owner
    }
  end

  def program_details
    {
      name: name,
      title: title,
      description: description,
      published: published,
      featured: featured,
      course_count: course_count || 0,
      member_count: member_count || 0,
      courses: lms_program_courses.includes(:course).ordered.map do |program_course|
        course = program_course.course
        {
          name: course.id,
          title: course.title,
          description: course.description,
          position: program_course.position,
          creation: program_course.creation&.strftime("%Y-%m-%d %H:%M:%S"),
          modified: program_course.modified&.strftime("%Y-%m-%d %H:%M:%S")
        }
      end,
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: modified&.strftime("%Y-%m-%d %H:%M:%S"),
      owner: owner
    }
  end

  private

  def update_name_from_title
    self.name ||= title&.parameterize&.upcase || generate_unique_name
  end

  def generate_unique_name
    base_name = title.parameterize.upcase
    counter = 1
    loop do
      candidate = "#{base_name}#{counter}"
      break candidate unless LmsProgram.exists?(name: candidate)
      counter += 1
    end
  end
end
