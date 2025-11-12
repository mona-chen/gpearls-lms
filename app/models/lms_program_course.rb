class LmsProgramCourse < ApplicationRecord
  # Associations
  belongs_to :lms_program
  belongs_to :course

  # Validations
  validates :lms_program_id, presence: true
  validates :course_id, presence: true
  validates :course_id, uniqueness: { scope: :lms_program_id }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 1 }

  # Callbacks
  before_validation :set_defaults
  after_create :update_program_course_count
  after_destroy :update_program_course_count

  # Scopes
  scope :ordered, -> { order(:position) }

  # Instance methods
  def move_to(new_position)
    return false unless new_position.is_a?(Integer) && new_position > 0

    # Find all courses in the program
    program_courses = lms_program.lms_program_courses.ordered.to_a

    # Remove current course from list
    program_courses.delete(self)

    # Insert at new position
    program_courses.insert(new_position - 1, self)

    # Update positions for all courses
    program_courses.each_with_index do |course, index|
      course.update!(position: index + 1)
    end

    true
  end

  # Frappe compatibility methods
  def to_frappe_format
    {
      name: id,
      program: lms_program_id,
      course: course_id,
      position: position,
      creation: creation&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: modified&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  private

  def set_defaults
    self.creation ||= Time.current
    self.modified ||= Time.current

    # Set position based on existing courses in the program
    if position.blank?
      max_position = lms_program.lms_program_courses.maximum(:position) || 0
      self.position = max_position + 1
    end
  end

  def update_program_course_count
    lms_program.update_counts
  end
end
