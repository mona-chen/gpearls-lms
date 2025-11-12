class LmsSetting < ApplicationRecord
  # Associations
  has_many :lms_settings, class_name: "LmsSetting", foreign_key: :parent, dependent: :destroy
  belongs_to :parent_setting, class_name: "LmsSetting", foreign_key: :parent, optional: true

  # Validations - simplified for table structure
  # validates :enable_learner_dashboard, presence: true

  # Scopes - simplified

  # Class methods - simplified for specific columns
  def self.get_value(key, default = nil)
    # For now, return defaults since we don't have key-value structure
    case key
    when "site_name"
      "LMS"
    when "logo_url"
      "/assets/lms/images/logo.svg"
    when "favicon_url"
      "/assets/lms/images/favicon.ico"
    when "footer_text"
      "© 2025 LMS. All rights reserved."
    else
      default
    end
  end

  def self.set_value(key, value, fieldtype = "Data")
    # Simplified - just return the value for now since we don't have key-value structure
    value
  end

  def self.get_single_value(field, default = nil)
    get_value(field, default)
  end

  def self.get_settings(prefix = nil)
    if prefix
      where("key LIKE ?", "#{prefix}%")
    else
      all
    end
  end

  # Instance methods - simplified

  def is_select?
    fieldtype == "Select"
  end

  def is_text?
    fieldtype == "Text"
  end

  def parsed_value
    return nil if value.blank?

    case fieldtype
    when "Check"
      value == "1" || value.downcase == "true"
    when "Select"
      value
    else
      value
    end
  end

  def to_frappe_format
    {
      name: key,
      value: value,
      fieldtype: fieldtype,
      parent: parent,
      creation: creation&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: modified&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  # Common LMS Settings
  def self.is_onboarding_complete
    # For now, return false since we don't have this column yet
    # In a real implementation, this would check a database column
    false
  end

  def self.set_onboarding_complete(status = true)
    # For now, just return the status since we don't have this column yet
    # In a real implementation, this would update a database column
    status
  end

  def self.enable_signup
    get_value("enable_signup", false)
  end

  def self.allow_guest_access
    get_value("allow_guest_access", false)
  end

  def self.default_course_image
    get_value("default_course_image", "/assets/lms/images/default-course.svg")
  end

  def self.site_name
    get_value("site_name", "LMS")
  end

  def self.site_description
    get_value("site_description", "Learning Management System")
  end

  def self.logo_url
    get_value("logo_url", "/assets/lms/images/logo.svg")
  end

  def self.favicon_url
    get_value("favicon_url", "/assets/lms/images/favicon.ico")
  end

  def self.primary_color
    get_value("primary_color", "#007bff")
  end

  def self.secondary_color
    get_value("secondary_color", "#6c757d")
  end

  def self.footer_text
    get_value("footer_text", "© 2025 LMS. All rights reserved.")
  end

  def self.contact_email
    get_value("contact_email", "admin@lms.test")
  end

  def self.support_email
    get_value("support_email", "support@lms.test")
  end

  def self.max_file_size
    get_value("max_file_size", "10").to_i.megabytes
  end

  def self.allowed_file_types
    get_value("allowed_file_types", "pdf,doc,docx,ppt,pptx,jpg,jpeg,png,gif").split(",")
  end

  def self.session_timeout
    get_value("session_timeout", "30").to_i.minutes
  end

  def self.enable_email_notifications
    get_value("enable_email_notifications", true)
  end

  def self.enable_push_notifications
    get_value("enable_push_notifications", false)
  end

  def self.enable_social_login
    get_value("enable_social_login", false)
  end

  def self.google_client_id
    get_value("google_client_id", "")
  end

  def self.facebook_app_id
    get_value("facebook_app_id", "")
  end

  def self.enable_ratings
    get_value("enable_ratings", true)
  end

  def self.enable_reviews
    get_value("enable_reviews", true)
  end

  def self.enable_discussions
    get_value("enable_discussions", true)
  end

  def self.enable_certificates
    get_value("enable_certificates", true)
  end

  def self.enable_badges
    get_value("enable_badges", true)
  end

  def self.enable_progress_tracking
    get_value("enable_progress_tracking", true)
  end

  def self.auto_save_progress
    get_value("auto_save_progress", true)
  end

  def self.course_completion_threshold
    get_value("course_completion_threshold", "80").to_i
  end

  def self.quiz_time_limit
    get_value("quiz_time_limit", "60").to_i.minutes
  end

  def self.allow_quiz_review
    get_value("allow_quiz_review", true)
  end

  def self.show_correct_answers
    get_value("show_correct_answers", false)
  end

  def self.enable_assignment_plagiarism_check
    get_value("enable_assignment_plagiarism_check", false)
  end

  def self.assignment_late_submission_penalty
    get_value("assignment_late_submission_penalty", "10").to_i
  end

  def self.enable_live_classes
    get_value("enable_live_classes", true)
  end

  def self.zoom_api_key
    get_value("zoom_api_key", "")
  end

  def self.zoom_api_secret
    get_value("zoom_api_secret", "")
  end

  def self.enable_zoom_integration
    get_value("enable_zoom_integration", false)
  end

  def self.custom_signup_content
    get_value("custom_signup_content", "")
  end

  def self.user_category_enabled?
    get_value("user_category", "").present?
  end
end
