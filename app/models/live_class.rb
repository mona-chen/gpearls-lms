class LiveClass < ApplicationRecord
  self.table_name = "lms_live_classes"
  belongs_to :batch, optional: true
  belongs_to :instructor, class_name: "User", foreign_key: "host", primary_key: "email", optional: true
  belongs_to :course, optional: true

  validates :name, :batch, presence: true
  validates :date, presence: true

  has_many :live_class_attendees, dependent: :destroy

  # Scopes for finding live classes
  scope :upcoming, -> { where("date >= ?", Date.today) }
  scope :past, -> { where("date < ?", Date.today) }
  scope :by_date, -> { order(:date, :time) }
  scope :for_batch, ->(batch) { where(batch: batch) }
  scope :for_instructor, ->(instructor) { where(instructor: instructor) }

  # Instance methods
  def upcoming?
    date >= Date.today
  end

  def past?
    date < Date.today
  end

  def today?
    date == Date.today
  end

  def instructor_name
    instructor&.full_name || instructor&.email
  end

  def course_title
    course&.title
  end

  def formatted_time
    return nil unless time
    time.strftime("%H:%M:%S")
  end

  def formatted_date
    date&.strftime("%Y-%m-%d")
  end

  def to_frappe_format
    {
      name: name,
      title: title,
      description: description,
      time: formatted_time,
      date: formatted_date,
      duration: duration,
      attendees: attendees || [],
      start_url: start_url,
      join_url: join_url,
      owner: instructor&.email,
      course_title: course_title
    }
  end

  # Class methods matching Frappe Python implementation
  def self.get_user_live_classes(user)
    batch_ids = BatchEnrollment.where(user: user).pluck(:batch_id)

    live_classes = where(batch_id: batch_ids)
                    .where("date >= ?", Date.today)
                    .order(:date)
                    .limit(2)

    live_classes.map(&:to_frappe_format)
  end

  def self.get_admin_live_classes(instructor)
    joins(:batch_courses)
      .where(batch_courses: { instructor: instructor })
      .where("date >= ?", Date.today)
      .by_date
      .limit(4)
  end

  def self.get_live_classes_for_batches(batch_ids)
    where(batch_id: batch_ids)
      .where("date >= ?", Date.today)
      .by_date
  end
end
