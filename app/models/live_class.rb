class LiveClass < ApplicationRecord
  self.table_name = "lms_live_classes"
  belongs_to :batch, optional: true
  belongs_to :instructor, class_name: "User", foreign_key: "host", optional: true
  belongs_to :course, optional: true
  belongs_to :zoom_account, class_name: "ZoomSetting", optional: true

  validates :title, presence: true
  validates :date, presence: true
  validates :time, presence: true
  validates :duration, presence: true
  validates :timezone, presence: true
  validates :host, presence: true

  has_many :live_class_participants, dependent: :destroy

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

  def batch_name
    batch&.title
  end

  def formatted_time
    return nil unless time
    time.strftime("%H:%M:%S")
  end

  def formatted_date
    date&.strftime("%Y-%m-%d")
  end

  def attendees_count
    live_class_participants.count
  end

  def name
    id.to_s
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "title" => title,
      "host" => host,
      "zoom_account" => zoom_account&.name,
      "batch_name" => batch_name,
      "date" => formatted_date,
      "time" => formatted_time,
      "duration" => duration,
      "timezone" => timezone,
      "description" => description,
      "event" => event,
      "auto_recording" => auto_recording,
      "meeting_id" => meeting_id,
      "uuid" => uuid,
      "attendees" => attendees_count,
      "password" => password,
      "start_url" => start_url,
      "join_url" => join_url,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
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
