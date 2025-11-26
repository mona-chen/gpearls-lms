class PwaInstallTracking < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, presence: true, inclusion: { in: %w[prompted accepted dismissed] }
  validates :platform, presence: true

  scope :by_action, ->(action) { where(action: action) }
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :recent, -> { where(timestamp: 1.week.ago..Time.current) }

  def self.track_install_event(user, action, platform, user_agent = nil)
    create!(
      user: user,
      action: action,
      platform: platform,
      user_agent: user_agent,
      timestamp: Time.current
    )
  end

  def self.get_install_analytics(date_range = nil)
    date_range ||= 1.month.ago..Time.current

    records = where(timestamp: date_range)

    {
      total_prompts: records.by_action("prompted").count,
      total_installs: records.by_action("accepted").count,
      total_dismissals: records.by_action("dismissed").count,
      install_rate: calculate_install_rate(records),
      platform_breakdown: platform_breakdown(records),
      daily_stats: daily_install_stats(records, date_range)
    }
  end

  private

  def self.calculate_install_rate(records)
    prompts = records.by_action("prompted").count
    installs = records.by_action("accepted").count

    return 0 if prompts.zero?

    (installs.to_f / prompts * 100).round(2)
  end

  def self.platform_breakdown(records)
    records.group(:platform, :action).count
  end

  def self.daily_install_stats(records, date_range)
    daily_stats = {}

    date_range.each do |date|
      day_records = records.where(timestamp: date.beginning_of_day..date.end_of_day)

      daily_stats[date.strftime("%Y-%m-%d")] = {
        prompts: day_records.by_action("prompted").count,
        installs: day_records.by_action("accepted").count,
        dismissals: day_records.by_action("dismissed").count
      }
    end

    daily_stats
  end
end
