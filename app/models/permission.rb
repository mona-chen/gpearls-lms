class Permission < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :doctype, presence: true
  validates :action, presence: true
  validates :role, presence: true

  # Scopes
  scope :by_doctype, ->(doctype) { where(doctype: doctype) }
  scope :by_role, ->(role) { where(role: role) }
  scope :by_action, ->(action) { where(action: action) }

  # Class methods
  def self.has_permission?(user, doctype, action, doc = nil)
    return true if user.system_manager? # System managers have all permissions

    user.roles_list.any? do |role_name|
      exists?(doctype: doctype, action: action, role: role_name)
    end
  end

  def self.create_default_permissions
    # Course permissions
    create_permission("Course Creator", "Course", "create", "Create courses")
    create_permission("Course Creator", "Course", "write", "Edit own courses")
    create_permission("Course Creator", "Course", "read", "Read courses")
    create_permission("Moderator", "Course", "write", "Edit any course")
    create_permission("Moderator", "Course", "delete", "Delete courses")
    create_permission("LMS Student", "Course", "read", "Read published courses")

    # Batch permissions
    create_permission("Course Creator", "Batch", "create", "Create batches")
    create_permission("Course Creator", "Batch", "write", "Edit own batches")
    create_permission("Batch Evaluator", "Batch", "write", "Evaluate batches")
    create_permission("LMS Student", "Batch", "read", "Read batches")

    # Assessment permissions
    create_permission("Course Creator", "Quiz", "create", "Create quizzes")
    create_permission("Batch Evaluator", "Quiz", "grade", "Grade quiz submissions")
    create_permission("LMS Student", "Quiz", "submit", "Submit quiz answers")

    # Job permissions
    create_permission("Course Creator", "Job Opportunity", "create", "Create job opportunities")
    create_permission("Moderator", "Job Opportunity", "delete", "Delete inappropriate jobs")
    create_permission("LMS Student", "Job Opportunity", "read", "View job opportunities")
    create_permission("LMS Student", "Job Opportunity", "apply", "Apply for jobs")

    # Discussion permissions
    create_permission("LMS Student", "Discussion", "create", "Create discussion topics")
    create_permission("LMS Student", "Discussion", "reply", "Reply to discussions")
    create_permission("Moderator", "Discussion", "moderate", "Moderate discussions")
  end

  private

  def self.create_permission(role, doctype, action, description)
    find_or_create_by!(
      name: "#{role} - #{doctype} - #{action}",
      role: role,
      doctype: doctype,
      action: action,
      description: description
    )
  end
end
