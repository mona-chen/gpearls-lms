# frozen_string_literal: true

class LmsBadge < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :course, class_name: "Course", optional: true
  belongs_to :batch, class_name: "Batch", optional: true

  has_many :badge_assignments, dependent: :destroy
  has_many :awarded_users, through: :badge_assignments, source: :user
  has_many :badge_requirements, dependent: :destroy
  has_many :badge_awards, dependent: :destroy
  has_many :badge_completions, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :title, presence: true
  validates :description, presence: true
  validates :badge_type, presence: true, inclusion: { in: ["Course Completion", "Quiz Master", "High Scorer", "Perfect Attendance", "Streak Champion", "Early Bird", "Helper", "Collaborator", "Innovator", "Top Performer", "First Timers", "Milestone", "Achievement", "Special"] }
  validates :category, presence: true, inclusion: { in: %w[Academic Performance Participation Engagement Collaboration Leadership Innovation Special] }
  validates :difficulty_level, presence: true, inclusion: { in: %w[Bronze Silver Gold Platinum Diamond Legendary] }, allow_nil: true
  validates :points, presence: true, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :level, presence: true, inclusion: { in: [1, 2, 3, 4, 5] }, allow_nil: true
  validates :tier, presence: true, inclusion: { in: %w[Basic Standard Premium Elite Legendary] }, allow_nil: true
  validates :color, presence: true, format: { with: /\A#[0-9a-fA-F]{6}\z/ }, allow_nil: true
  validates :icon, presence: true, allow_nil: true
  validates :status, presence: true, inclusion: { in: %w[Active Inactive Archived Draft] }
  validates :issuance_limit, presence: true, numericality: { greater_than: 0 }, allow_nil: true
  validates :expires_after_days, presence: true, numericality: { greater_than: 0 }, allow_nil: true
  validates :is_hidden, inclusion: { in: [true, false] }, allow_nil: true
  validates :is_system_generated, inclusion: { in: [true, false] }, allow_nil: true

  # Scopes
  scope :active, -> { where(status: "Active") }
  scope :inactive, -> { where(status: "Inactive") }
  scope :archived, -> { where(status: "Archived") }
  scope :draft, -> { where(status: "Draft") }
  scope :by_type, ->(type) { where(badge_type: type) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_difficulty, ->(difficulty) { where(difficulty_level: difficulty) }
  scope :by_level, ->(level) { where(level: level) }
  scope :by_tier, ->(tier) { where(tier: tier) }
  scope :by_owner, ->(owner) { where(owner: owner) }
  scope :by_course, ->(course) { where(course: course) }
  scope :by_batch, ->(batch) { where(batch: batch) }
  scope :course_completion, -> { where(badge_type: "Course Completion") }
  scope :quiz_master, -> { where(badge_type: "Quiz Master") }
  scope :high_scorer, -> { where(badge_type: "High Scorer") }
  scope :perfect_attendance, -> { where(badge_type: "Perfect Attendance") }
  scope :streak_champion, -> { where(badge_type: "Streak Champion") }
  scope :early_bird, -> { where(badge_type: "Early Bird") }
  scope :helper, -> { where(badge_type: "Helper") }
  scope :collaborator, -> { where(badge_type: "Collaborator") }
  scope :innovator, -> { where(badge_type: "Innovator") }
  scope :top_performer, -> { where(badge_type: "Top Performer") }
  scope :first_timers, -> { where(badge_type: "First Timers") }
  scope :milestone, -> { where(badge_type: "Milestone") }
  scope :achievement, -> { where(badge_type: "Achievement") }
  scope :special, -> { where(badge_type: "Special") }
  scope :visible, -> { where(is_hidden: false) }
  scope :hidden, -> { where(is_hidden: true) }
  scope :system_generated, -> { where(is_system_generated: true) }
  scope :user_created, -> { where(is_system_generated: false) }
  scope :bronze, -> { where(difficulty_level: "Bronze") }
  scope :silver, -> { where(difficulty_level: "Silver") }
  scope :gold, -> { where(difficulty_level: "Gold") }
  scope :platinum, -> { where(difficulty_level: "Platinum") }
  scope :diamond, -> { where(difficulty_level: "Diamond") }
  scope :legendary, -> { where(difficulty_level: "Legendary") }
  scope :basic, -> { where(tier: "Basic") }
  scope :standard, -> { where(tier: "Standard") }
  scope :premium, -> { where(tier: "Premium") }
  scope :elite, -> { where(tier: "Elite") }
  scope :legendary_tier, -> { where(tier: "Legendary") }

  # Callbacks
  before_validation :set_default_values
  after_create :create_badge_requirements
  after_update :update_badge_visibility
  after_save :sync_with_badge_system

  # Instance Methods
  def active?
    status == "Active"
  end

  def inactive?
    status == "Inactive"
  end

  def archived?
    status == "Archived"
  end

  def draft?
    status == "Draft"
  end

  def visible?
    !is_hidden
  end

  def hidden?
    is_hidden
  end

  def system_generated?
    is_system_generated
  end

  def user_created?
    !is_system_generated
  end

  def course_completion?
    badge_type == "Course Completion"
  end

  def quiz_master?
    badge_type == "Quiz Master"
  end

  def high_scorer?
    badge_type == "High Scorer"
  end

  def perfect_attendance?
    badge_type == "Perfect Attendance"
  end

  def streak_champion?
    badge_type == "Streak Champion"
  end

  def early_bird?
    badge_type == "Early Bird"
  end

  def helper?
    badge_type == "Helper"
  end

  def collaborator?
    badge_type == "Collaborator"
  end

  def innovator?
    badge_type == "Innovator"
  end

  def top_performer?
    badge_type == "Top Performer"
  end

  def first_timers?
    badge_type == "First Timers"
  end

  def milestone?
    badge_type == "Milestone"
  end

  def achievement?
    badge_type == "Achievement"
  end

  def special?
    badge_type == "Special"
  end

  def bronze?
    difficulty_level == "Bronze"
  end

  def silver?
    difficulty_level == "Silver"
  end

  def gold?
    difficulty_level == "Gold"
  end

  def platinum?
    difficulty_level == "Platinum"
  end

  def diamond?
    difficulty_level == "Diamond"
  end

  def legendary?
    difficulty_level == "Legendary"
  end

  def basic?
    tier == "Basic"
  end

  def standard?
    tier == "Standard"
  end

  def premium?
    tier == "Premium"
  end

  def elite?
    tier == "Elite"
  end

  def legendary_tier?
    tier == "Legendary"
  end

  def can_be_awarded_to?(user)
    return false unless active?
    return false if issuance_limit && issuance_limit > 0 && user.badge_assignments.where(badge: self).count >= issuance_limit

    true
  end

  def has_been_awarded_to?(user)
    user.badge_assignments.exists?(badge: self)
  end

  def get_award_count(user)
    user.badge_assignments.where(badge: self).count
  end

  def get_total_awards
    badge_assignments.count
  end

  def get_unique_awarded_users
    awarded_users.count
  end

  def get_awarded_users_count
    awarded_users.count
  end

  def get_recent_awards(limit = 10)
    badge_assignments.includes(:user)
                  .order(awarded_at: :desc)
                  .limit(limit)
                  .map(&:to_frappe_format)
  end

  def get_award_statistics
    awards = badge_assignments.includes(:user)

    {
      total_awards: awards.count,
      unique_users: awarded_users.count,
      recent_awards: awards.order(awarded_at: :desc).limit(10).map(&:to_frappe_format),
      awards_by_date: get_awards_by_date(awards),
      awards_by_course: get_awards_by_course(awards),
      awards_by_batch: get_awards_by_batch(awards)
    }
  end

  def get_badge_progress(user)
    return { progress: 0, completed: false } unless user

    user_assignments = user.badge_assignments.where(badge: self)

    if user_assignments.present?
      {
        progress: 100,
        completed: true,
        awarded_at: user_assignments.first.awarded_at,
        current_count: user_assignments.count
      }
    else
      {
        progress: 0,
        completed: false,
        current_count: 0
      }
    end
  end

  def get_requirements_for_user(user)
    requirements = badge_requirements.includes(:requirement)
    user_progress = []

    requirements.each do |badge_req|
      requirement = badge_req.requirement
      user_progress << {
        requirement: requirement.to_frappe_format,
        completed: requirement.completed_for_user?(user),
        progress: requirement.get_progress_for_user(user)
      }
    end

    user_progress
  end

  def is_eligible_for_user?(user)
    return false unless active?

    requirements = badge_requirements
    return true if requirements.empty?

    requirements.all? do |badge_req|
      requirement = badge_req.requirement
      requirement.completed_for_user?(user)
    end
  end

  def to_frappe_format
    {
      id: id,
      name: name,
      title: title,
      description: description,
      badge_type: badge_type,
      category: category,
      difficulty_level: difficulty_level,
      points: points,
      level: level,
      tier: tier,
      color: color,
      icon: icon,
      image: image_url,
      owner: owner&.to_frappe_format,
      course: course&.to_frappe_format,
      batch: batch&.to_frappe_format,
      status: status,
      issuance_limit: issuance_limit,
      expires_after_days: expires_after_days,
      is_hidden: is_hidden,
      is_system_generated: is_system_generated,
      total_awards: get_total_awards,
      unique_users: get_unique_awarded_users,
      recent_awards: get_recent_awards,
      requirements_count: badge_requirements.count,
      awarded_count: get_awarded_users_count,
      progress_percentage: calculate_progress_percentage,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end

  # Class Methods
  def self.create_badge(params)
    badge = build_badge_with_defaults(params)

    if badge.save
      # Create badge requirements if provided
      if params[:requirements].present?
        create_requirements_for_badge(badge, params[:requirements])
      end

      # Create default requirements for certain badge types
      if params[:create_default_requirements]
        create_default_requirements(badge, params)
      end

      {
        success: true,
        badge: badge,
        message: "Badge created successfully"
      }
    else
      {
        success: false,
        error: "Failed to create badge",
        details: badge.errors.full_messages
      }
    end
  end

  def self.get_badges(options = {})
    badges = includes(:owner, :course, :badge_assignments, :badge_requirements)

    # Apply filters
    badges = badges.where(status: options[:status]) if options[:status].present?
    badges = badges.where(badge_type: options[:badge_type]) if options[:badge_type].present?
    badges = badges.where(category: options[:category]) if options[:category].present?
    badges = badges.where(difficulty_level: options[:difficulty]) if options[:difficulty].present?
    badges = badges.where(level: options[:level]) if options[:level].present?
    badges = badges.where(tier: options[:tier]) if options[:tier].present?
    badges = badges.where(owner: options[:owner]) if options[:owner].present?
    badges = badges.where(course: options[:course]) if options[:course].present?
    badges = badges.where(batch: options[:batch]) if options[:batch].present?

    # Apply visibility filter
    badges = badges.where(is_hidden: false) if options[:visible_only]

    # Apply sorting
    if options[:sort_by] == "name"
      badges = badges.order(:name)
    elsif options[:sort_by] == "created_at"
      badges = badges.order(created_at: :desc)
    elsif options[:sort_by] == "points"
      badges = badges.order(points: :desc)
    elsif options[:sort_by] == "difficulty"
      badges = badges.order("CASE difficulty_level WHEN \"Bronze\" THEN 1 WHEN \"Silver\" THEN 2 WHEN \"Gold\" THEN 3 WHEN \"Platinum\" THEN 4 WHEN \"Diamond\" THEN 5 WHEN \"Legendary\" THEN 6 END")
    else
      badges = badges.order(created_at: :desc)
    end

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    badges = badges.limit(limit).offset(offset)

    badges.map(&:to_frappe_format)
  end

  def self.get_user_badges(user, options = {})
    badges = user.badge_assignments.includes(:badge)
                  .where(badge: { status: "Active" })
                  .includes(:badge => [:owner, :course, :batch])

    # Apply filters
    badges = badges.joins(:badge).where("lms_badges.badge_type": options[:badge_type]) if options[:badge_type].present?
    badges = badges.joins(:badge).where("lms_badges.category": options[:category]) if options[:category].present?
    badges = badges.joins(:badge).where("lms_badges.difficulty_level": options[:difficulty]) if options[:difficulty].present?
    badges = badges.joins(:badge).where("lms_badges.level": options[:level]) if options[:level].present?
    badges = badges.joins(:badge).where("lms_badges.tier": options[:tier]) if options[:tier].present?

    # Apply sorting
    if options[:sort_by] == "name"
      badges = badges.joins(:badge).order("lms_badges.name")
    elsif options[:sort_by] == "awarded_at"
      badges = badges.order(awarded_at: :desc)
    elsif options[:sort_by] == "points"
      badges = badges.joins(:badge).order("lms_badges.points": :desc)
    else
      badges = badges.order(awarded_at: :desc)
    end

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    badges = badges.limit(limit).offset(offset)

    badges.map { |assignment| assignment.badge.to_frappe_format.merge(awarded_at: assignment.awarded_at&.iso8601) }
  end

  def self.get_badges_by_type(badge_type, options = {})
    badges = where(badge_type: badge_type, status: "Active")
             .includes(:owner, :course, :badge_assignments, :badge_requirements)

    # Apply filters
    badges = badges.where(category: options[:category]) if options[:category].present?
    badges = badges.where(difficulty_level: options[:difficulty]) if options[:difficulty].present?
    badges = badges.where(level: options[:level]) if options[:level].present?
    badges = badges.where(tier: options[:tier]) if options[:tier].present?
    badges = badges.where(owner: options[:owner]) if options[:owner].present?
    badges = badges.where(course: options[:course]) if options[:course].present?

    # Apply sorting
    badges = badges.order(created_at: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    badges = badges.limit(limit).offset(offset)

    badges.map(&:to_frappe_format)
  end

  def self.get_badges_by_category(category, options = {})
    badges = where(category: category, status: "Active")
             .includes(:owner, :course, :badge_assignments, :badge_requirements)

    # Apply filters
    badges = badges.where(badge_type: options[:badge_type]) if options[:badge_type].present?
    badges = badges.where(difficulty_level: options[:difficulty]) if options[:difficulty].present?
    badges = badges.where(level: options[:level]) if options[:level].present?
    badges = badges.where(tier: options[:tier]) if options[:tier].present?
    badges = badges.where(owner: options[:owner]) if options[:owner].present?
    badges = badges.where(course: options[:course]) if options[:course].present?

    # Apply sorting
    badges = badges.order(created_at: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    badges = badges.limit(limit).offset(offset)

    badges.map(&:to_frappe_format)
  end

  def self.get_badges_by_difficulty(difficulty, options = {})
    badges = where(difficulty_level: difficulty, status: "Active")
             .includes(:owner, :course, :badge_assignments, :badge_requirements)

    # Apply filters
    badges = badges.where(badge_type: options[:badge_type]) if options[:badge_type].present?
    badges = badges.where(category: options[:category]) if options[:category].present?
    badges = badges.where(level: options[:level]) if options[:level].present?
    badges = badges.where(tier: options[:tier]) if options[:tier].present?
    badges = badges.where(owner: options[:owner]) if options[:owner].present?
    badges = badges.where(course: options[:course]) if options[:course].present?

    # Apply sorting
    badges = badges.order(created_at: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    badges = badges.limit(limit).offset(offset)

    badges.map(&:to_frappe_format)
  end

  def self.search_badges(search_term, options = {})
    return [] if search_term.blank?

    badges = where("name ILIKE ? OR title ILIKE ? OR description ILIKE ? OR category ILIKE ? OR badge_type ILIKE ?",
                    "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%")
             .where(status: "Active")
             .includes(:owner, :course, :badge_assignments)

    # Apply filters
    badges = badges.where(badge_type: options[:badge_type]) if options[:badge_type].present?
    badges = badges.where(category: options[:category]) if options[:category].present?
    badges = badges.where(difficulty_level: options[:difficulty]) if options[:difficulty].present?
    badges = badges.where(level: options[:level]) if options[:level].present?
    badges = badges.where(tier: options[:tier]) if options[:tier].present?

    # Apply sorting
    badges = badges.order(created_at: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    badges = badges.limit(limit).offset(offset)

    badges.map(&:to_frappe_format)
  end

  def self.get_badge_statistics(badge_id)
    badge = find_by(id: badge_id)
    return { error: "Badge not found" } unless badge

    awards = badge.badge_assignments.includes(:user, :course, :batch)

    {
      success: true,
      badge_id: badge_id,
      badge_name: badge.name,
      badge_type: badge.badge_type,
      category: badge.category,
      difficulty_level: badge.difficulty_level,
      points: badge.points,
      level: badge.level,
      tier: badge.tier,
      total_awards: awards.count,
      unique_users: badge.awarded_users_count,
      recent_awards: awards.order(awarded_at: :desc).limit(10).map { |award| { user: award.user.to_frappe_format, awarded_at: award.awarded_at&.iso8601 } },
      awards_by_date: get_awards_by_date(awards),
      awards_by_course: get_awards_by_course(awards),
      awards_by_batch: get_awards_by_batch(awards),
      award_progression: get_award_progression(awards),
      completion_rate: calculate_completion_rate(awards),
      average_time_to_earn: calculate_average_time_to_earn(awards),
      badge_progression: get_badge_progression(awards)
    }
  end

  def self.duplicate_badge(original_badge, new_name, options = {})
    return { error: "Original badge not found" } unless original_badge

    # Create new badge with duplicated properties
    new_badge = original_badge.dup
    new_badge.name = new_name
    new_badge.title = "#{original_badge.title} (Copy)"
    new_badge.status = "Draft"
    new_badge.is_system_generated = false

    if new_badge.save
      # Duplicate badge requirements
      original_badge.badge_requirements.each do |original_requirement|
        new_requirement = original_requirement.dup
        new_requirement.badge_id = new_badge.id
        new_requirement.save
      end

      {
        success: true,
        badge: new_badge,
        message: "Badge duplicated successfully"
      }
    else
      {
        success: false,
        error: "Failed to duplicate badge",
        details: new_badge.errors.full_messages
      }
    end
  end

  def self.check_user_eligibility(user, badge_id)
    badge = find_by(id: badge_id)
    return { error: "Badge not found" } unless badge

    eligibility = {
      badge_id: badge_id,
      badge_name: badge.name,
      user_id: user.id,
      user_email: user.email,
      eligible: badge.is_eligible_for_user?(user),
      requirements: badge.get_requirements_for_user(user),
      progress: badge.get_badge_progress(user),
      awards_count: badge.get_award_count(user),
      issuance_limit_reached: badge.issuance_limit && badge.issuance_limit > 0 && badge.get_award_count(user) >= badge.issuance_limit,
      requirements_met: badge.is_eligible_for_user?(user)
    }
  end

  def self.award_badge_to_user(user, badge_id, options = {})
    badge = find_by(id: badge_id)
    return { error: "Badge not found" } unless badge

    # Check eligibility
    unless badge.is_eligible_for_user?(user)
      return { error: "User is not eligible for this badge" }
    end

    # Check issuance limit
    if badge.issuance_limit && badge.issuance_limit > 0 && badge.get_award_count(user) >= badge.issuance_limit
      return { error: "User has reached the issuance limit for this badge" }
    end

    # Create badge award
    badge_award = BadgeAward.create!(
      badge: badge,
      user: user,
      awarded_at: Time.current,
      awarded_by: options[:awarded_by],
      context: options[:context],
      metadata: options[:metadata] || {}
    )

    # Create badge assignment
    assignment = BadgeAssignment.create!(
      badge: badge,
      user: user,
      awarded_at: Time.current,
      status: "Awarded",
      expires_at: badge.expires_after_days ? badge.expires_after_days.days.from_now : nil,
      award_context: options[:context],
      award_metadata: options[:metadata] || {}
    )

    # Trigger badge award notifications
    # Notifications::BadgeNotificationService.send_badge_award_notification(user, badge, assignment)

    # Update user badge progress
    # Users::BadgeProgressService.update_badge_progress(user, badge)

    {
      success: true,
      badge_id: badge_id,
      badge_name: badge.name,
      user_id: user.id,
      user_email: user.email,
      award_id: badge_award.id,
      assignment_id: assignment.id,
      awarded_at: assignment.awarded_at&.iso8601,
      expires_at: assignment.expires_at&.iso8601,
      status: assignment.status
    }
  end

  def self.revoke_badge_from_user(user, badge_id, options = {})
    badge = find_by(id: badge_id)
    return { error: "Badge not found" } unless badge

    assignment = user.badge_assignments.find_by(badge_id: badge_id)
    return { error: "User does not have this badge" } unless assignment

    # Update assignment status
    assignment.update!(
      status: "Revoked",
      revoked_at: Time.current,
      revocation_reason: options[:reason],
      revoked_by: options[:revoked_by]
    )

    # Trigger badge revocation notifications
    # Notifications::BadgeNotificationService.send_badge_revocation_notification(user, badge, assignment)

    # Update user badge progress
    # Users::BadgeProgressService.update_badge_progress(user, badge)

    {
      success: true,
      badge_id: badge_id,
      badge_name: badge.name,
      user_id: user.id,
      user_email: user.email,
      assignment_id: assignment.id,
      revoked_at: assignment.revoked_at&.iso8601,
      revocation_reason: assignment.revocation_reason
    }
  end

  private

  def set_default_values
    self.status ||= "Draft"
    self.category ||= "Academic"
    self.difficulty_level ||= "Bronze"
    self.points ||= 10
    self.level ||= 1
    self.tier ||= "Basic"
    self.color ||= "#3B82F6"
    self.issuance_limit ||= nil
    self.expires_after_days ||= nil
    self.is_hidden ||= false
    self.is_system_generated ||= false
  end

  def create_badge_requirements
    # Create default requirements based on badge type
    case badge_type
    when "Course Completion"
      create_course_completion_requirements
    when "Quiz Master"
      create_quiz_master_requirements
    when "High Scorer"
      create_high_scorer_requirements
    when "Perfect Attendance"
      create_perfect_attendance_requirements
    when "Streak Champion"
      create_streak_champion_requirements
    when "Early Bird"
      create_early_bird_requirements
    when "Helper"
      create_helper_requirements
    when "Collaborator"
      create_collaborator_requirements
    when "Innovator"
      create_innovator_requirements
    when "Top Performer"
      create_top_performer_requirements
    end
  end

  def create_requirements_for_badge(badge, requirements)
    requirements.each_with_index do |req, index|
      badge.badge_requirements.create!(
        requirement: req[:requirement],
        description: req[:description],
        condition_type: req[:condition_type] || "completion",
        condition_value: req[:condition_value],
        position: index + 1
      )
    end
  end

  def create_default_requirements(badge, options)
    # Create system-generated requirements based on badge type
    case badge.badge_type
    when "Course Completion"
      badge.badge_requirements.create!(
        requirement_type: "course_completion",
        description: "Complete the course with minimum required score",
        condition_type: "course_completion_percentage",
        condition_value: options[:course_completion_percentage] || 100
      )
    when "Quiz Master"
      badge.badge_requirements.create!(
        requirement_type: "quiz_performance",
        description: "Score 90% or higher on all quizzes",
        condition_type: "quiz_average_score",
        condition_value: options[:quiz_average_score] || 90
      )
    when "High Scorer"
      badge.badge_requirements.create!(
        requirement_type: "assessment_performance",
        description: "Score 95% or higher on all assessments",
        condition_type: "assessment_average_score",
        condition_value: options[:assessment_average_score] || 95
      )
    end
  end

  def update_badge_visibility
    # Update badge visibility based on status
    if status_changed? && status == "Active"
      # Make badge visible to users
      # BadgeVisibilityService.make_visible(self)
    elsif status_changed? && status == "Archived"
      # Hide badge from users
      # BadgeVisibilityService.hide_badge(self)
    end
  end

  def sync_with_badge_system
    # Sync with external badge system if configured
    # ExternalBadgeSystemService.sync_badge(self)
  end

  def create_course_completion_requirements
    badge_requirements.create!(
      requirement_type: "course_completion",
      description: "Complete the course with minimum required score",
      condition_type: "course_completion_percentage",
      condition_value: 100
    )
  end

  def create_quiz_master_requirements
    badge_requirements.create!(
      requirement_type: "quiz_performance",
      description: "Score 90% or higher on all quizzes",
      condition_type: "quiz_average_score",
      condition_value: 90
    )
  end

  def create_high_scorer_requirements
    badge_requirements.create!(
      requirement_type: "assessment_performance",
      description: "Score 95% or higher on all assessments",
      condition_type: "assessment_average_score",
      condition_value: 95
    )
  end

  def create_perfect_attendance_requirements
    badge_requirements.create!(
      requirement_type: "attendance",
      description: "Maintain 100% attendance for all sessions",
      condition_type: "attendance_percentage",
      condition_value: 100
    )
  end

  def create_streak_champion_requirements
    badge_requirements.create!(
      requirement_type: "activity_streak",
      description: "Maintain a learning streak for 30 consecutive days",
      condition_type: "activity_streak_days",
      condition_value: 30
    )
  end

  def create_early_bird_requirements
    badge_requirements.create!(
      requirement_type: "early_submission",
      description: "Submit all assignments before the deadline",
      condition_type: "early_submission_percentage",
      condition_value: 100
    )
  end

  def create_helper_requirements
    badge_requirements.create!(
      requirement_type: "peer_review",
      description: "Provide helpful feedback to at least 5 peers",
      condition_type: "peer_review_count",
      condition_value: 5
    )
  end

  def create_collaborator_requirements
    badge_requirements.create!(
      requirement_type: "collaboration",
      description: "Participate in at least 3 group projects",
      condition_type: "group_project_count",
      condition_value: 3
    )
  end

  def create_innovator_requirements
    badge_requirements.create!(
      requirement_type: "innovation",
      description: "Submit an innovative solution or idea",
      condition_type: "innovation_score",
      condition_value: 85
    )
  end

  def create_top_performer_requirements
    badge_requirements.create!(
      requirement_type: "top_performance",
      description: "Achieve top 10% ranking in course",
      condition_type: "course_ranking",
      condition_value: 10
    )
  end

  def calculate_progress_percentage
    return 0 if badge_assignments.empty?

    unique_users = awarded_users.count
    potential_users = get_potential_eligible_users_count

    return 0 if potential_users.zero?

    (unique_users.to_f / potential_users * 100).round(2)
  end

  def update_award_count
    # This would be called after badge assignments to update statistics
    # For now, just ensure the badge is marked as updated
    touch
  end

  def get_potential_eligible_users_count
    # Estimate the number of users who could potentially earn this badge
    if course && batch
      batch.enrollments.count
    elsif course
      course.enrollments.count
    else
      # Estimate based on all active users
      User.active.count
    end
  end

  def get_awards_by_date(awards)
    return {} if awards.empty?

    awards.group_by_day(:awarded_at).count
           .transform_keys(&:to_s)
  end

  def get_awards_by_course(awards)
    return {} if awards.empty?

    awards.joins(:user, "JOIN enrollments ON users.id = enrollments.user_id")
         .group("enrollments.course_id")
         .count
         .transform_keys { |k, v| [Course.find(k).name, v] }.to_h
  end

  def get_awards_by_batch(awards)
    return {} if awards.empty?

    awards.joins(:user, "JOIN batch_enrollments ON users.id = batch_enrollments.user_id")
         .group("batch_enrollments.batch_id")
         .count
         .transform_keys { |k, v| [Batch.find(k).name, v] }.to_h
  end

  def get_award_progression(awards)
    return {} if awards.empty?

    monthly_awards = awards.group_by_month(:awarded_at).count
    progression = {}

    months_ago = (Date.current - 12.months)..Date.current
    months_ago.each do |month|
      month_name = month.strftime("%Y-%m")
      progression[month_name] = monthly_awards[month_name] || 0
    end

    progression
  end

  def calculate_completion_rate(awards)
    return 0 if awards.empty?

    completed_awards = awards.where.not(expires_at: nil)
                              .where("expires_at > ?", Time.current)
    expired_awards = awards.where(expires_at: true)
                              .where("expires_at <= ?", Time.current)

    total = completed_awards.count + expired_awards.count
    return 0 if total.zero?

    (completed_awards.count.to_f / total * 100).round(2)
  end

  def calculate_average_time_to_earn(awards)
    return 0 if awards.empty?

    # Calculate time from user start to badge award for each award
    # This would require tracking user enrollment start time
    # For now, return average days between awards
    30 # Placeholder value
  end

  def get_badge_progression(awards)
    return {} if awards.empty?

    # Track how badges are earned over time
    # This would require tracking when users first become eligible
    # For now, return monthly progress data
    get_award_progression(awards)
  end

  def image_url
    # Return the URL of the badge image
    # This would be stored in an asset management system
    # For now, return a placeholder
    "/assets/badges/#{id}.png" if id.present?
  end

  private

  def build_badge_with_defaults(params)
    LmsBadge.new(
      name: params[:name],
      title: params[:title],
      description: params[:description],
      badge_type: params[:badge_type],
      category: params[:category] || "Academic",
      difficulty_level: params[:difficulty_level] || "Bronze",
      points: params[:points] || 10,
      level: params[:level] || 1,
      tier: params[:tier] || "Basic",
      color: params[:color] || "#3B82F6",
      icon: params[:icon],
      image: params[:image],
      owner: params[:owner],
      course: params[:course],
      batch: params[:batch],
      status: params[:status] || "Draft",
      issuance_limit: params[:issuance_limit],
      expires_after_days: params[:expires_after_days],
      is_hidden: params[:is_hidden] || false,
      is_system_generated: params[:is_system_generated] || false
    )
  end
end
