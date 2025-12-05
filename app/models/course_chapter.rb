class CourseChapter < ApplicationRecord
  self.table_name = "course_chapters"
  self.primary_key = "name"

  # Frappe-style fields
  attribute :name, :string
  attribute :owner, :string
  attribute :creation, :datetime
  attribute :modified, :datetime
  attribute :modified_by, :string
  attribute :docstatus, :string, default: "0"
  attribute :parent, :string
  attribute :parenttype, :string
  attribute :parentfield, :string
  attribute :idx, :integer

  belongs_to :course, class_name: "Course", foreign_key: "course"
  has_many :lessons, -> { order(:idx) }, class_name: "CourseLesson", foreign_key: "chapter", dependent: :destroy

  validates :title, presence: true
  validates :course, presence: true

  # Scopes
  scope :for_course, ->(course) { where(course: course) }
  scope :scorm_packages, -> { where(is_scorm_package: true) }

  # Instance methods
  def total_lessons
    lessons.count
  end

  def name
    self[:name] || "#{course}-#{title.parameterize}"
  end

  def to_frappe_format
    {
      "name" => name,
      "title" => title,
      "course" => course,
      "course_title" => course_title,
      "is_scorm_package" => is_scorm_package,
      "scorm_package" => scorm_package,
      "scorm_package_path" => scorm_package_path,
      "manifest_file" => manifest_file,
      "launch_file" => launch_file,
      "lessons" => total_lessons,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "owner" => owner || "Administrator"
    }
  end
end
