module System
  class AppsService
    def self.call
      # Return Frappe-style apps list (similar to Frappe Cloud response)
      apps = [
        {
          name: "LMS",
          title: "Learning Management System",
          description: "Complete learning management solution",
          icon: "lms",
          color: "green",
          route: "/lms",
          app_name: "lms",
          category: "Education",
          publisher: "LMS Team",
          license: "MIT",
          installation_status: "Installed",
          installed_version: "1.0.0",
          latest_version: "1.0.0",
          update_available: false,
          docs_url: "https://docs.lms.com",
          repository_url: "https://github.com/lms/lms"
        }
      ]

      apps
    end
  end
end
