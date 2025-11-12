module Analytics
  class HeatmapDataService
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      return { heatmap_data: [], total_activities: 0, weeks: 0 } unless @user

      date_range = calculate_date_range
      date_count = initialize_date_count(date_range)
      activity_data = fetch_activity_data(date_range)

      populate_activity_counts(date_count, activity_data)
      heatmap_data = format_heatmap_data(date_count, date_range)

      total_activities = date_count.values.sum
      weeks = calculate_weeks(date_range)

      {
        heatmap_data: heatmap_data,
        total_activities: total_activities,
        weeks: weeks
      }
    end

    private

    def calculate_date_range
      base_days = 200
      base_date = Date.today - base_days.days
      start_date = base_date - base_date.wday.days
      end_date = Date.today + (6 - Date.today.wday).days
      [ start_date, end_date ]
    end

    def initialize_date_count(date_range)
      start_date, end_date = date_range
      date_count = {}
      (start_date..end_date).each do |date|
        date_count[date.to_s] = 0
      end
      date_count
    end

    def fetch_activity_data(date_range)
      start_date, end_date = date_range
      LessonProgress.where(
        user: @user,
        completed: true,
        last_accessed_at: start_date..end_date
      ).pluck(:last_accessed_at)
    end

    def populate_activity_counts(date_count, activity_data)
      activity_data.each do |date|
        date_key = date.to_date.to_s
        date_count[date_key] += 1 if date_count.key?(date_key)
      end
    end

    def format_heatmap_data(date_count, date_range)
      start_date, end_date = date_range
      days_of_week = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ]

      days_of_week.map do |day|
        day_data = []
        current_date = start_date

        while current_date <= end_date
          if current_date.strftime("%a") == day
            date_key = current_date.to_s
            count = date_count[date_key] || 0
            day_data << {
              date: date_key,
              count: count,
              label: "#{count} activities on #{current_date.strftime('%d %b')}"
            }
          end
          current_date += 1.day
        end

        { name: day, data: day_data }
      end
    end

    def calculate_weeks(date_range)
      start_date, end_date = date_range
      ((end_date - start_date).to_i + 1) / 7
    end
  end
end
