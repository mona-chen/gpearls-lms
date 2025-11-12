class BatchCourse < ApplicationRecord
  belongs_to :batch
  belongs_to :course
  belongs_to :evaluator, class_name: "User", optional: true

  # Validations
  validates :batch, presence: true
  validates :course, presence: true
  validates :batch_id, uniqueness: { scope: :course_id }
  validates :evaluator, presence: { if: -> { course&.certificate_enabled } }

  # Callbacks
  after_create :create_course_enrollments_for_batch_members
  after_destroy :remove_course_enrollments_for_batch_members

  # Scopes
  scope :with_evaluator, -> { where.not(evaluator_id: nil) }
  scope :by_course, ->(course) { where(course: course) }
  scope :by_batch, ->(batch) { where(batch: batch) }

  # Instance methods
  def evaluator_name
    evaluator&.full_name
  end

  def evaluator_email
    evaluator&.email
  end

  def course_title
    course&.title
  end

  def batch_title
    batch&.title
  end

  def to_frappe_format
    {
      name: id,
      course: course&.name || course&.id,
      course_title: course&.title,
      evaluator: evaluator&.email,
      evaluator_name: evaluator&.full_name,
      batch: batch&.name || batch&.id,
      batch_title: batch&.title,
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  private

  def create_course_enrollments_for_batch_members
    return unless batch && course

    batch.batch_enrollments.includes(:user).find_each do |batch_enrollment|
      next unless batch_enrollment.user

      # Create or find course enrollment
      enrollment = Enrollment.find_or_initialize_by(
        user: batch_enrollment.user,
        course: course
      )

      enrollment.member_type = "Student"
      enrollment.role = "Member"
      enrollment.batch = batch
      enrollment.save if enrollment.new_record? || enrollment.changed?
    end
  end

  def remove_course_enrollments_for_batch_members
    return unless batch && course

    batch.batch_enrollments.includes(:user).find_each do |batch_enrollment|
      next unless batch_enrollment.user

      # Remove course enrollment only if user is not enrolled in course through other batches
      other_batch_courses = BatchCourse.where(course: course)
                                     .where.not(batch: batch)
                                     .joins(:batch)
                                     .where(batches: { id: batch_enrollment.user.batch_enrollments.select(:batch_id) })

      if other_batch_courses.empty?
        enrollment = Enrollment.find_by(user: batch_enrollment.user, course: course)
        enrollment&.destroy
      end
    end
  end
end
