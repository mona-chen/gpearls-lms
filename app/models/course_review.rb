class CourseReview < ApplicationRecord
  self.table_name = "lms_course_reviews"

  # Associations
  # Note: course and owner are stored as strings, not foreign keys
  # belongs_to :course, class_name: "Course", foreign_key: "course"
  # belongs_to :user, foreign_key: :owner, primary_key: :email, optional: true

  # Validations
  validates :course, presence: true
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :review, length: { maximum: 500 }, allow_blank: true
  validates :owner, presence: true

  # Callbacks
  before_create :set_creation_date
  before_save :set_modified_date

  # Scopes
  scope :published, -> { where(docstatus: "0") }
  scope :by_rating, ->(rating) { where(rating: rating) }
  scope :recent, -> { order(creation: :desc) }
  scope :highest_rated, -> { order(rating: :desc) }

  # Class Methods
  def self.average_rating_for(course)
    where(course: course, docstatus: "0").average(:rating).to_f.round(1)
  end

  def self.total_reviews_for(course)
    where(course: course, docstatus: "0").count
  end

  def self.rating_distribution_for(course)
    where(course: course, docstatus: "0")
      .group(:rating)
      .count
      .transform_keys(&:to_s)
  end

  # Instance Methods
  def published?
    docstatus == "0"
  end

  def draft?
    docstatus == "1"
  end

  def cancelled?
    docstatus == "2"
  end

  def to_frappe_format
    {
      name: name,
      owner: owner,
      review: review,
      rating: rating,
      course: course.name,
      course_title: course.title,
      creation: creation&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: modified&.strftime("%Y-%m-%d %H:%M:%S"),
      docstatus: docstatus
    }
  end

  private

  def set_creation_date
    self.creation ||= Time.current
  end

   def set_modified_date
     self.modified = Time.current
     self.modified_by = owner
   end
end
