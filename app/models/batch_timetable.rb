# frozen_string_literal: true

class BatchTimetable < ApplicationRecord
  self.table_name = "lms_batch_timetables"
  belongs_to :batch, foreign_key: :parent, primary_key: :name
  belongs_to :reference_doc, polymorphic: true, optional: true

  # Validations
  validates :batch, presence: true
  validates :date, presence: true
  validates :start_time, presence: true

  # Scopes
  scope :by_batch, ->(batch) { where(batch: batch) }
  scope :by_date, ->(date) { where(date: date) }

  # Instance methods
  def to_frappe_format
    {
      name: id,
      batch: batch&.name || batch&.id,
      batch_name: batch&.title,
      reference_doctype: reference_doctype,
      reference_docname: reference_docname,
      date: date&.strftime("%Y-%m-%d"),
      start_time: start_time&.strftime("%H:%M:%S"),
      end_time: end_time&.strftime("%H:%M:%S"),
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  def get_title
    return reference_doc&.title if reference_doc
    return reference_doctype + " - " + reference_docname if reference_doctype && reference_docname
    "Untitled"
  end
end
