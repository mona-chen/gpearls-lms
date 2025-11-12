module Notifications
  class FrappeHelper
    # Helper class to provide Frappe-like functions in notification templates

    def format_date(date, format = nil)
      return "" unless date
      format ||= "%Y-%m-%d"
      date.strftime(format)
    end

    def format_datetime(datetime, format = nil)
      return "" unless datetime
      format ||= "%Y-%m-%d %H:%M:%S"
      datetime.strftime(format)
    end

    def get_url(path)
      # Return full URL for a path
      "#{base_url}#{path}"
    end

    def get_value(doctype, name, fieldname)
      # Simulate frappe.db.get_value
      # In real implementation, this would query the database
      # For now, return a placeholder
      "#{doctype}:#{name}:#{fieldname}"
    end

    def get_fullname(user)
      return "" unless user
      if user.respond_to?(:full_name)
        user.full_name
      elsif user.respond_to?(:first_name) && user.respond_to?(:last_name)
        "#{user.first_name} #{user.last_name}".strip
      else
        user.to_s
      end
    end

    def get_user_image(user)
      return "" unless user
      user.respond_to?(:user_image) ? user.user_image : ""
    end

    def _(text)
      # Translation function placeholder
      text
    end

    private

    def base_url
      # Get base URL from environment or configuration
      ENV.fetch("BASE_URL", "http://localhost:3001")
    end
  end
end
