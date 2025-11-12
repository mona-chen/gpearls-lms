class LmsFile < ApplicationRecord
  # Associations
  belongs_to :uploaded_by, class_name: "User", optional: true

  # Validations
  validates :file_name, :file_url, presence: true
  validates :file_size, numericality: { greater_than: 0 }, allow_nil: true

  # Scopes
  scope :public_files, -> { where(is_private: false) }
  scope :private_files, -> { where(is_private: true) }
  scope :attachments_for, ->(doctype, name) { where(attached_to_doctype: doctype, attached_to_name: name) }
  scope :uploaded_by_user, ->(user) { where(uploaded_by: user) }

  # Callbacks
  before_save :set_uploaded_at, if: :new_record?

  # Class methods
  def self.max_file_size
    LmsSetting.max_file_size
  end

  def self.allowed_file_types
    LmsSetting.allowed_file_types
  end

  # Instance methods
  def file_extension
    File.extname(file_name).downcase
  end

  def content_type_from_extension
    case file_extension
    when ".pdf" then "application/pdf"
    when ".doc" then "application/msword"
    when ".docx" then "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    when ".xls" then "application/vnd.ms-excel"
    when ".xlsx" then "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    when ".ppt" then "application/vnd.ms-powerpoint"
    when ".pptx" then "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    when ".txt" then "text/plain"
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".png" then "image/png"
    when ".gif" then "image/gif"
    when ".zip" then "application/zip"
    else "application/octet-stream"
    end
  end

  def to_frappe_format
    {
      name: id,
      file_name: file_name,
      file_url: file_url,
      file_type: file_type || content_type_from_extension,
      file_size: file_size,
      is_private: is_private,
      attached_to_doctype: attached_to_doctype,
      attached_to_name: attached_to_name,
      uploaded_by: uploaded_by&.full_name,
      creation: created_at.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  private

  def set_uploaded_at
    self.uploaded_at ||= Time.current
  end
end
