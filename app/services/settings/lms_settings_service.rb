module Settings
  class LmsSettingsService
    def self.call(field: nil)
      new(field).call
    end

    def initialize(field)
      @field = field
    end

    def call
      if @field.present?
        # Return raw value like Frappe Cloud (not wrapped in object)
        settings[@field] || false
      else
        # Return full settings object wrapped in message
        { message: settings }
      end
    end

    private

    def settings
      @settings ||= begin
        # Try to load from database first
        db_settings = load_database_settings
        return db_settings if db_settings.any?

        # Fall back to default settings
        default_settings
      end
    end

    def load_database_settings
      # Try to get settings from Setting model if it exists
      begin
        Setting.all.each_with_object({}) do |setting, hash|
          hash[setting.key.to_sym] = setting.value
        end
      rescue => e
        Rails.logger.warn "Could not load settings from database: #{e.message}"
        {}
      end
    end

    def default_settings
      {
        allow_guest_access: true,
        enable_student_portal: true,
        enable_course_creation: true,
        enable_batch_creation: true,
        enable_certification: true,
        enable_discussions: true,
        enable_quizzes: true,
        enable_assignments: true,
        enable_programming_exercises: true,
        enable_live_classes: true,
        enable_analytics: true,
        enable_notifications: true,
        enable_jobs: true,
        enable_reviews: true,
        enable_ratings: true,
        enable_tags: true,
        enable_categories: true,
        enable_search: true,
        enable_bookmarks: true,
        enable_notes: true,
        enable_progress_tracking: true,
        enable_certificates: true,
        enable_badges: true,
        enable_leaderboard: true,
        enable_social_learning: true,
        enable_mobile_app: true,
        enable_pwa: true,
        enable_dark_mode: true,
        enable_multilingual: true,
        default_language: "en",
        supported_languages: ["en"],
        timezone: "UTC",
        date_format: "YYYY-MM-DD",
        time_format: "24h",
        currency: "USD",
        currency_symbol: "$",
        decimal_places: 2,
        thousands_separator: ",",
        decimal_separator: ".",
        country: "US",
        region: ""
      }
    end
  end
end
