module Settings
  class SidebarSettingsService
    def self.call
      new.call
    end

    def initialize
      # Load sidebar settings from LmsSetting model
    end

    def call
      # Return Frappe-style sidebar settings format
      # Values: 1 = show item, 0 = hide item
      {
        "courses" => fetch_setting("sidebar_courses", 1),
        "batches" => fetch_setting("sidebar_batches", 1),
        "certifications" => fetch_setting("sidebar_certifications", 1),
        "jobs" => fetch_setting("sidebar_jobs", 1),
        "statistics" => fetch_setting("sidebar_statistics", 1),
        "notifications" => fetch_setting("sidebar_notifications", 1),
        "programming_exercises" => fetch_setting("sidebar_programming_exercises", 1),
        "my_courses" => fetch_setting("sidebar_my_courses", 1),
        "my_batches" => fetch_setting("sidebar_my_batches", 1),
        "profile" => fetch_setting("sidebar_profile", 1),
        "settings" => fetch_setting("sidebar_settings", 1),
        "logout" => fetch_setting("sidebar_logout", 1),
        "web_pages" => fetch_web_pages
      }
    end

    private

    def fetch_setting(key, default)
      # For now, return defaults since LmsSetting table structure is different
      default
    end

    def fetch_web_pages
      # TODO: Load from database when web pages feature is implemented
      # For now, return empty array
      []
    end
  end
end
