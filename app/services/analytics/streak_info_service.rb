module Analytics
  class StreakInfoService
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      return default_streak_info unless @user

      activity_dates = fetch_activity_dates
      current_streak = calculate_current_streak(activity_dates)
      longest_streak = calculate_longest_streak(activity_dates)
      total_days = activity_dates.count
      last_activity_date = activity_dates.first

      {
        current_streak: current_streak,
        longest_streak: longest_streak,
        total_days: total_days,
        last_activity_date: last_activity_date
      }
    end

    private

    def default_streak_info
      {
        current_streak: 0,
        longest_streak: 0,
        total_days: 0,
        last_activity_date: nil
      }
    end

    def fetch_activity_dates
      LessonProgress.where(user: @user)
        .where("last_accessed_at >= ?", 30.days.ago)
        .order(last_accessed_at: :desc)
        .pluck(:last_accessed_at)
        .map(&:to_date)
        .uniq
    end

    def calculate_current_streak(dates)
      return 0 if dates.empty?

      streak = 0
      current_date = Date.today

      dates.each do |date|
        if date == current_date || date == current_date - 1
          streak += 1
          current_date -= 1
        else
          break
        end
      end

      streak
    end

    def calculate_longest_streak(dates)
      return 0 if dates.empty?

      longest_streak = 0
      current_streak = 0
      previous_date = nil

      dates.sort.each do |date|
        if previous_date && (date == previous_date + 1 || date == previous_date)
          current_streak += 1
        else
          current_streak = 1
        end

        longest_streak = [ longest_streak, current_streak ].max
        previous_date = date
      end

      longest_streak
    end
  end
end
