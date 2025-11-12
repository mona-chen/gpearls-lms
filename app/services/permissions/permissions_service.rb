module Permissions
  class PermissionsService
    def self.can?(user, action, resource_type, resource = nil)
      return false unless user

      # Check basic role-based permissions first
      case action
      when :create_course
        user.instructor?
      when :edit_course
        user.instructor? || user.moderator? || (resource && resource.instructor == user)
      when :delete_course
        user.moderator? || (resource && resource.instructor == user)
      when :view_course
        true # Everyone can view published courses
      when :enroll_course
        !user.enrollments.exists?(course: resource) if resource
      when :create_batch
        user.instructor?
      when :evaluate_batch
        user.evaluator?
      when :moderate_content
        user.moderator?
      when :create_job
        user.instructor?
      when :report_job
        user.student?
      when :moderate_job
        user.moderator?
      when :apply_job
        user.student?
      else
        # Fall back to granular permission system
        Permission.has_permission?(user, resource_type.to_s, action.to_s, resource)
      end
    end

    def self.authorize!(user, action, resource_type, resource = nil)
      unless can?(user, action, resource_type, resource)
        raise PermissionError.new("Insufficient permissions for #{action} on #{resource_type}")
      end
    end

    def self.filter_accessible_resources(user, resources, action = :read)
      resources.select do |resource|
        can?(user, action, resource.class.name, resource)
      end
    end

    # Frappe-compatible permission checking
    def self.check_permissions(user, doctype, permtype, doc = nil)
      case permtype
      when "read"
        can?(user, :read, doctype, doc)
      when "write"
        can?(user, :write, doctype, doc)
      when "create"
        can?(user, :create, doctype, doc)
      when "delete"
        can?(user, :delete, doctype, doc)
      else
        false
      end
    end
  end

  class PermissionError < StandardError
    def initialize(message = "Permission denied")
      super(message)
    end
  end
end
