# frozen_string_literal: true

class LmsAssessment < ApplicationRecord
  self.table_name = "lms_assessments"

  # Associations
  belongs_to :batch, foreign_key: "parent", primary_key: "name", optional: false
  belongs_to :creator, class_name: "User", foreign_key: "owner", optional: true

  has_many :assessment_questions, dependent: :destroy
  has_many :assessment_submissions, dependent: :destroy
  has_many :assessment_evaluations, dependent: :destroy
  has_many :assessment_attempts, dependent: :destroy
  has_many :assessment_notifications, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: { scope: :course }
  validates :title, presence: true
  validates :description, presence: true
  validates :course, presence: true
  validates :creator, presence: true
  validates :assessment_type, presence: true, inclusion: { in: %w[Quiz Assignment Exam Project Survey Coding Written] }
  validates :max_marks, presence: true, numericality: { greater_than: 0 }
  validates :passing_marks, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: :max_marks }, allow_nil: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }, allow_nil: true
  validates :status, presence: true, inclusion: { in: %w[Draft Published Ended] }
  validates :difficulty_level, presence: true, inclusion: { in: %w[Easy Medium Hard] }, allow_nil: true
  validates :attempts_allowed, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 10 }, allow_nil: true
  validates :total_questions, presence: true, numericality: { greater_than: 0 }, allow_nil: true
  validates :randomize_questions, inclusion: { in: [ true, false ] }, allow_nil: true
  validates :show_immediate_results, inclusion: { in: [ true, false ] }, allow_nil: true
  validates :allow_review, inclusion: { in: [ true, false ] }, allow_nil: true
  validates :require_proctoring, inclusion: { in: [ true, false ] }, allow_nil: true

  # Scopes
  scope :draft, -> { where(status: "Draft") }
  scope :published, -> { where(status: "Published") }
  scope :ended, -> { where(status: "Ended") }
  scope :by_course, ->(course) { where(course: course) }
  scope :by_creator, ->(creator) { where(creator: creator) }
  scope :by_assessment_type, ->(type) { where(assessment_type: type) }
  scope :by_difficulty, ->(difficulty) { where(difficulty_level: difficulty) }
  scope :by_status, ->(status) { where(status: status) }
  scope :active, -> { where(status: "Published").where("start_date <= ? AND (end_date >= ? OR end_date IS NULL)", Time.current, Time.current) }
  scope :upcoming, -> { where(status: "Published").where("start_date > ?", Time.current) }
  scope :overdue, -> { where(status: "Published").where("end_date < ?", Time.current) }
  scope :quiz_type, -> { where(assessment_type: "Quiz") }
  scope :assignment_type, -> { where(assessment_type: "Assignment") }
  scope :exam_type, -> { where(assessment_type: "Exam") }
  scope :project_type, -> { where(assessment_type: "Project") }
  scope :survey_type, -> { where(assessment_type: "Survey") }
  scope :coding_type, -> { where(assessment_type: "Coding") }
  scope :written_type, -> { where(assessment_type: "Written") }

  # Callbacks
  before_validation :set_default_values
  after_save :update_course_assessment_cache
  after_save :send_notification_if_published

  # Instance Methods
  def draft?
    status == "Draft"
  end

  def published?
    status == "Published"
  end

  def ended?
    status == "Ended"
  end

  def active?
    published? && (start_date.nil? || start_date <= Time.current) && (end_date.nil? || end_date > Time.current)
  end

  def upcoming?
    published? && start_date && start_date > Time.current
  end

  def overdue?
    published? && end_date && end_date < Time.current
  end

  def can_start?(user)
    return false unless active?
    return false unless has_remaining_attempts?(user)
    return false unless user.enrolled_in?(course)
    return true if attempts_allowed.nil? || attempts_allowed > 0
    false
  end

  def has_remaining_attempts?(user)
    return true if attempts_allowed.nil?

    used_attempts = assessment_attempts.where(user: user).count
    used_attempts < attempts_allowed
  end

  def quiz_type?
    assessment_type == "Quiz"
  end

  def assignment_type?
    assessment_type == "Assignment"
  end

  def exam_type?
    assessment_type == "Exam"
  end

  def project_type?
    assessment_type == "Project"
  end

  def survey_type?
    assessment_type == "Survey"
  end

  def coding_type?
    assessment_type == "Coding"
  end

  def written_type?
    assessment_type == "Written"
  end

  def requires_proctoring?
    require_proctoring || (exam_type? && difficulty_level == "Hard")
  end

  def time_remaining
    return nil unless end_date && status == "Published"

    remaining_time = end_date - Time.current
    remaining_time > 0 ? remaining_time.round : 0
  end

  def time_until_start
    return nil unless start_date && status == "Published" && start_date > Time.current

    remaining_time = start_date - Time.current
    remaining_time > 0 ? remaining_time.round : 0
  end

  def get_questions_for_user(user, options = {})
    questions = assessment_questions.includes(:question)

    if randomize_questions?
      questions = questions.sample(total_questions || questions.count)
    else
      questions = questions.limit(total_questions || questions.count)
    end

    # Shuffle questions if requested
    questions = questions.shuffle if options[:shuffle]

    questions
  end

  def calculate_user_score(user)
    latest_attempt = assessment_attempts.where(user: user).order(created_at: :desc).first
    return 0 unless latest_attempt

    latest_attempt.score || 0
  end

  def calculate_user_percentage(user)
    latest_attempt = assessment_attempts.where(user: user).order(created_at: :desc).first
    return 0 unless latest_attempt

    latest_attempt.percentage || 0
  end

  def get_user_attempt_count(user)
    assessment_attempts.where(user: user).count
  end

  def get_user_best_attempt(user)
    assessment_attempts.where(user: user).order(score: :desc, percentage: :desc).first
  end

  def get_user_latest_attempt(user)
    assessment_attempts.where(user: user).order(created_at: :desc).first
  end

  def get_user_attempts(user)
    assessment_attempts.where(user: user).order(created_at: :asc).includes(:assessment_submissions, :assessment_evaluations)
  end

  def get_submission_statistics
    submissions = assessment_submissions.includes(:user, :assessment_questions)

    {
      total_submissions: submissions.count,
      unique_users: submissions.count("user_id"),
      average_score: submissions.average(:score)&.round(2) || 0,
      highest_score: submissions.maximum(:score) || 0,
      lowest_score: submissions.minimum(:score) || 0,
      average_time: submissions.average(:time_taken_seconds)&.round(2) || 0,
      pass_rate: calculate_pass_rate(submissions),
      score_distribution: get_score_distribution(submissions),
      time_distribution: get_time_distribution(submissions),
      daily_submissions: get_daily_submissions(submissions),
      user_performance: get_user_performance(submissions)
    }
  end

  def to_frappe_format
    {
      id: id,
      name: name,
      title: title,
      description: description,
      assessment_type: assessment_type,
      course: course&.to_frappe_format,
      batch: batch&.to_frappe_format,
      creator: creator&.to_frappe_format,
      evaluator: evaluator&.to_frappe_format,
      max_marks: max_marks,
      passing_marks: passing_marks,
      duration_minutes: duration_minutes,
      status: status,
      difficulty_level: difficulty_level,
      start_date: start_date&.iso8601,
      end_date: end_date&.iso8601,
      published_at: published_at&.iso8601,
      ended_at: ended_at&.iso8601,
      attempts_allowed: attempts_allowed,
      total_questions: total_questions,
      randomize_questions: randomize_questions,
      show_immediate_results: show_immediate_results,
      allow_review: allow_review,
      require_proctoring: require_proctoring,
      total_submissions: assessment_submissions.count,
      unique_users: assessment_submissions.count("user_id"),
      average_score: assessment_submissions.average(:score)&.round(2) || 0,
      pass_rate: calculate_pass_rate(assessment_submissions),
      active: active?,
      time_remaining: time_remaining,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end

  # Class Methods
  def self.create_assessment(params)
    assessment = build_assessment_with_defaults(params)

    if assessment.save
      # Add questions if provided
      if params[:questions].present?
        add_questions_to_assessment(assessment, params[:questions])
      end

      # Create default assessment questions if quiz type and no questions provided
      if assessment.quiz_type? && assessment.assessment_questions.empty?
        create_default_quiz_questions(assessment, params)
      end

      {
        success: true,
        assessment: assessment,
        message: "Assessment created successfully"
      }
    else
      {
        success: false,
        error: "Failed to create assessment",
        details: assessment.errors.full_messages
      }
    end
  end

  def self.get_course_assessments(course, options = {})
    assessments = course.assessments.includes(:creator, :batch, :assessment_questions, :assessment_submissions)

    # Apply filters
    assessments = assessments.where(status: options[:status]) if options[:status].present?
    assessments = assessments.where(creator: options[:creator]) if options[:creator].present?
    assessments = assessments.where(assessment_type: options[:assessment_type]) if options[:assessment_type].present?
    assessments = assessments.where(difficulty_level: options[:difficulty]) if options[:difficulty].present?
    assessments = assessments.where(batch: options[:batch]) if options[:batch].present?

    # Apply sorting
    if options[:sort_by] == "name"
      assessments = assessments.order(:name)
    elsif options[:sort_by] == "created_at"
      assessments = assessments.order(created_at: :desc)
    elsif options[:sort_by] == "start_date"
      assessments = assessments.order(start_date: :asc)
    else
      assessments = assessments.order(created_at: :desc)
    end

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    assessments = assessments.limit(limit).offset(offset)

    assessments.map(&:to_frappe_format)
  end

  def self.get_user_assessments(user, options = {})
    assessments = user.created_assessments.includes(:course, :batch, :assessment_questions, :assessment_submissions)

    # Apply filters
    assessments = assessments.where(status: options[:status]) if options[:status].present?
    assessments = assessments.where(assessment_type: options[:assessment_type]) if options[:assessment_type].present?
    assessments = assessments.where(course: options[:course]) if options[:course].present?

    # Apply sorting
    assessments = assessments.order(created_at: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    assessments = assessments.limit(limit).offset(offset)

    assessments.map(&:to_frappe_format)
  end

  def self.get_active_assessments(options = {})
    assessments = active.includes(:course, :creator, :batch, :assessment_questions, :assessment_submissions)

    # Apply filters
    assessments = assessments.where(course: options[:course]) if options[:course].present?
    assessments = assessments.where(creator: options[:creator]) if options[:creator].present?
    assessments = assessments.where(assessment_type: options[:assessment_type]) if options[:assessment_type].present?

    # Apply sorting
    assessments = assessments.order(end_date: :asc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    assessments = assessments.limit(limit).offset(offset)

    assessments.map(&:to_frappe_format)
  end

  def self.get_upcoming_assessments(options = {})
    assessments = where(status: "Published")
                     .where("start_date > ?", Time.current)
                     .includes(:course, :creator, :batch, :assessment_questions, :assessment_submissions)

    # Apply filters
    assessments = assessments.where(course: options[:course]) if options[:course].present?
    assessments = assessments.where(creator: options[:creator]) if options[:creator].present?
    assessments = assessments.where(assessment_type: options[:assessment_type]) if options[:assessment_type].present?

    # Apply sorting
    assessments = assessments.order(start_date: :asc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    assessments = assessments.limit(limit).offset(offset)

    assessments.map(&:to_frappe_format)
  end

  def self.get_assessment_statistics(assessment_id)
    assessment = find_by(id: assessment_id)
    return { error: "Assessment not found" } unless assessment

    submissions = assessment.assessment_submissions.includes(:user, :assessment_questions, :assessment_evaluations)
    attempts = assessment.assessment_attempts.includes(:user, :assessment_submissions, :assessment_evaluations)

    {
      success: true,
      assessment_id: assessment_id,
      assessment_name: assessment.name,
      assessment_type: assessment.assessment_type,
      total_submissions: submissions.count,
      unique_users: submissions.count("user_id"),
      total_attempts: attempts.count,
      unique_users_attempted: attempts.count("user_id"),
      average_score: submissions.average(:score)&.round(2) || 0,
      highest_score: submissions.maximum(:score) || 0,
      lowest_score: submissions.minimum(:score) || 0,
      average_time: submissions.average(:time_taken_seconds)&.round(2) || 0,
      pass_rate: calculate_pass_rate(submissions),
      score_distribution: get_score_distribution(submissions),
      time_distribution: get_time_distribution(submissions),
      daily_submissions: get_daily_submissions(submissions),
      user_performance: get_user_performance(submissions),
      attempt_statistics: get_attempt_statistics(attempts),
      question_performance: get_question_performance(assessment),
      assessment_type_statistics: get_assessment_type_statistics(assessment, submissions),
      difficulty_analysis: get_difficulty_analysis(assessment, submissions)
    }
  end

  def self.duplicate_assessment(original_assessment, new_name, options = {})
    return { error: "Original assessment not found" } unless original_assessment

    # Create new assessment with duplicated properties
    new_assessment = original_assessment.dup
    new_assessment.name = new_name
    new_assessment.title = "#{original_assessment.title} (Copy)"
    new_assessment.status = "Draft"
    new_assessment.published_at = nil
    new_assessment.ended_at = nil

    if new_assessment.save
      # Duplicate assessment questions
      original_assessment.assessment_questions.each do |original_question|
        new_question = original_question.dup
        new_question.assessment_id = new_assessment.id
        new_question.save
      end

      {
        success: true,
        assessment: new_assessment,
        message: "Assessment duplicated successfully"
      }
    else
      {
        success: false,
        error: "Failed to duplicate assessment",
        details: new_assessment.errors.full_messages
      }
    end
  end

  def self.search_assessments(search_term, options = {})
    return [] if search_term.blank?

    assessments = where("name ILIKE ? OR title ILIKE ? OR description ILIKE ?",
                    "%#{search_term}%", "%#{search_term}%", "%#{search_term}%")
             .includes(:course, :creator, :batch, :assessment_questions)

    # Apply filters
    assessments = assessments.where(status: options[:status]) if options[:status].present?
    assessments = assessments.where(assessment_type: options[:assessment_type]) if options[:assessment_type].present?
    assessments = assessments.where(course: options[:course]) if options[:course].present?

    # Apply sorting
    assessments = assessments.order(created_at: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    assessments = assessments.limit(limit).offset(offset)

    assessments.map(&:to_frappe_format)
  end

  def self.get_assessments_by_type(assessment_type, options = {})
    assessments = where(assessment_type: assessment_type)
             .includes(:course, :creator, :assessment_questions, :assessment_submissions)

    # Apply filters
    assessments = assessments.where(status: options[:status]) if options[:status].present?
    assessments = assessments.where(course: options[:course]) if options[:course].present?

    # Apply sorting
    assessments = assessments.order(created_at: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    assessments = assessments.limit(limit).offset(offset)

    assessments.map(&:to_frappe_format)
  end

  def self.get_assessments_by_difficulty(difficulty, options = {})
    assessments = where(difficulty_level: difficulty)
             .includes(:course, :creator, :assessment_questions, :assessment_submissions)

    # Apply filters
    assessments = assessments.where(status: options[:status]) if options[:status].present?
    assessments = assessments.where(assessment_type: options[:assessment_type]) if options[:assessment_type].present?

    # Apply sorting
    assessments = assessments.order(created_at: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    assessments = assessments.limit(limit).offset(offset)

    assessments.map(&:to_frappe_format)
  end

  private

  def set_default_values
    self.status ||= "Draft"
    self.max_marks ||= 100
    self.passing_marks ||= 50
    self.duration_minutes ||= 60
    self.difficulty_level ||= "Medium"
    self.attempts_allowed ||= 1
    self.total_questions ||= 10
    self.randomize_questions ||= false
    self.show_immediate_results ||= true
    self.allow_review ||= true
    self.require_proctoring ||= false
  end

  def update_course_assessment_cache
    nil unless course

    # Update course assessment cache
    # Courses::AssessmentCacheService.update_cache(course)
  end

  def send_notification_if_published
    nil unless status_changed? && published?

    # Send notification to enrolled students
    # Notifications::AssessmentNotificationService.publish_assessment_notification(self)
  end

  def add_questions_to_assessment(assessment, questions)
    questions.each_with_index do |question, index|
      assessment.assessment_questions.create!(
        question: question,
        marks: question.marks || 10,
        position: index + 1
      )
    end
  end

  def create_default_quiz_questions(assessment, options = {})
    # Get default questions for quiz type
    questions = options[:default_questions] || get_default_quiz_questions(assessment)

    questions.each_with_index do |question, index|
      assessment.assessment_questions.create!(
        question: question,
        marks: question.marks || 10,
        position: index + 1
      )
    end
  end

  def get_default_quiz_questions(assessment)
    # Get questions from course question bank if available
    if assessment.course && assessment.course.lms_questions.present?
      assessment.course.lms_questions.active.limit(assessment.total_questions || 10)
    else
      []
    end
  end

  def calculate_pass_rate(submissions)
    return 0 if submissions.empty?

    passing_count = submissions.select { |submission| submission.score >= passing_marks }.count
    (passing_count.to_f / submissions.count * 100).round(2)
  end

  def get_score_distribution(submissions)
    return {} if submissions.empty?

    ranges = {
      "0-59" => 0,
      "60-69" => 0,
      "70-79" => 0,
      "80-89" => 0,
      "90-100" => 0
    }

    submissions.each do |submission|
      percentage = (submission.score.to_f / max_marks * 100).round
      case percentage
      when 0..59
        ranges["0-59"] += 1
      when 60..69
        ranges["60-69"] += 1
      when 70..79
        ranges["70-79"] += 1
      when 80..89
        ranges["80-89"] += 1
      when 90..100
        ranges["90-100"] += 1
      end
    end

    ranges
  end

  def get_time_distribution(submissions)
    return {} if submissions.empty?

    ranges = {
      "0-5 min" => 0,
      "5-10 min" => 0,
      "10-20 min" => 0,
      "20-30 min" => 0,
      "30+ min" => 0
    }

    submissions.each do |submission|
      time_minutes = (submission.time_taken_seconds || 0) / 60
      case time_minutes
      when 0..5
        ranges["0-5 min"] += 1
      when 5..10
        ranges["5-10 min"] += 1
      when 10..20
        ranges["10-20 min"] += 1
      when 20..30
        ranges["20-30 min"] += 1
      else
        ranges["30+ min"] += 1
      end
    end

    ranges
  end

  def get_daily_submissions(submissions)
    return {} if submissions.empty?

    daily_counts = submissions.group_by_day(:submitted_at).count
    daily_counts.transform_keys(&:to_s)
  end

  def get_user_performance(submissions)
    return {} if submissions.empty?

    user_performance = {}
    submissions.group_by(&:user).each do |user, user_submissions|
      user_performance[user.email] = {
        attempts: user_submissions.count,
        best_score: user_submissions.maximum(:score) || 0,
        average_score: user_submissions.average(:score)&.round(2) || 0,
        best_percentage: user_submissions.maximum(:percentage) || 0,
        average_percentage: user_submissions.average(:percentage)&.round(2) || 0,
        passed: user_submissions.select(&:passed?).count,
        failed: user_submissions.select(&:failed?).count,
        total_time: user_submissions.sum(:time_taken_seconds) || 0,
        improvement_trend: calculate_improvement_trend(user_submissions)
      }
    end

    user_performance
  end

  def get_attempt_statistics(attempts)
    return {} if attempts.empty?

    attempt_stats = {
      single_attempt: attempts.where("attempt_number = 1").count,
      multiple_attempts: attempts.where("attempt_number > 1").count,
      average_attempts: attempts.average(:attempt_number)&.round(2) || 0,
      max_attempts: attempts.maximum(:attempt_number) || 0
    }

    # Performance by attempt number
    (1..(attempt_stats[:max_attempts] || 1)).each do |attempt_num|
      attempt_submissions = attempts.where(attempt_number: attempt_num)
      next if attempt_submissions.empty?

      attempt_stats["attempt_#{attempt_num}"] = {
        count: attempt_submissions.count,
        average_score: attempt_submissions.average(:score)&.round(2) || 0,
        best_score: attempt_submissions.maximum(:score) || 0,
        pass_rate: attempt_submissions.select(&:passed?).count.to_f / attempt_submissions.count * 100
      }
    end

    attempt_stats
  end

  def get_question_performance(assessment)
    question_performance = {}

    assessment.assessment_questions.includes(:question, :assessment_submissions).each do |aq|
      question_submissions = aq.assessment_submissions

      question_performance[aq.question_id] = {
        question: aq.question.to_frappe_format,
        total_submissions: question_submissions.count,
        correct_submissions: question_submissions.select(&:correct?).count,
        incorrect_submissions: question_submissions.select { |s| !s.correct? }.count,
        accuracy_rate: calculate_question_accuracy_rate(question_submissions),
        average_marks: question_submissions.average(:score)&.round(2) || 0,
        max_marks: aq.marks,
        time_distribution: get_question_time_distribution(question_submissions)
      }
    end

    question_performance
  end

  def get_assessment_type_statistics(assessment, submissions)
    {
      assessment_type: assessment.assessment_type,
      total_assessments: 1,
      total_submissions: submissions.count,
      unique_users: submissions.count("user_id"),
      average_score: submissions.average(:score)&.round(2) || 0,
      pass_rate: calculate_pass_rate(submissions),
      common_difficulty: submissions.joins(:assessment).group(:difficulty_level).count.max_by { |k, v| k }
    }
  end

  def get_difficulty_analysis(assessment, submissions)
    difficulty_stats = submissions.joins(:assessment)
                          .group(:difficulty_level)
                          .count

    {
      distribution: difficulty_stats,
      most_common: difficulty_stats.max_by { |k, v| k },
      performance_by_difficulty: get_performance_by_difficulty(submissions)
    }
  end

  def calculate_question_accuracy_rate(question_submissions)
    return 0 if question_submissions.empty?

    correct_count = question_submissions.select(&:correct?).count
    total_count = question_submissions.count

    return 0 if total_count.zero?

    (correct_count.to_f / total_count * 100).round(2)
  end

  def get_question_time_distribution(question_submissions)
    return {} if question_submissions.empty?

    ranges = {
      "0-2 min" => 0,
      "2-5 min" => 0,
      "5-10 min" => 0,
      "10+ min" => 0
    }

    question_submissions.each do |submission|
      time_minutes = (submission.time_taken_seconds || 0) / 60
      case time_minutes
      when 0..2
        ranges["0-2 min"] += 1
      when 2..5
        ranges["2-5 min"] += 1
      when 5..10
        ranges["5-10 min"] += 1
      else
        ranges["10+ min"] += 1
      end
    end

    ranges
  end

  def get_performance_by_difficulty(submissions)
    submissions.joins(:assessment)
               .group(:difficulty_level)
               .average(:score)
  end

  def calculate_improvement_trend(user_submissions)
    return 0 if user_submissions.length <= 1

    sorted_submissions = user_submissions.sort_by(:created_at)
    improvements = []

    sorted_submissions.each_with_index do |submission, index|
      next if index == 0
      previous_score = sorted_submissions[index - 1].score
      improvement = submission.score - previous_score
      improvements << improvement
    end

    return 0 if improvements.empty?

    improvements.sum / improvements.length.round(2)
  end

  private

  def build_assessment_with_defaults(params)
    LmsAssessment.new(
      name: params[:name],
      title: params[:title],
      description: params[:description],
      course: params[:course],
      batch: params[:batch],
      creator: params[:creator],
      evaluator: params[:evaluator],
      assessment_type: params[:assessment_type],
      max_marks: params[:max_marks] || 100,
      passing_marks: params[:passing_marks] || 50,
      duration_minutes: params[:duration_minutes] || 60,
      status: params[:status] || "Draft",
      difficulty_level: params[:difficulty_level] || "Medium",
      start_date: params[:start_date],
      end_date: params[:end_date],
      published_at: params[:published_at],
      ended_at: params[:ended_at],
      attempts_allowed: params[:attempts_allowed] || 1,
      total_questions: params[:total_questions] || 10,
      randomize_questions: params[:randomize_questions] || false,
      show_immediate_results: params[:show_immediate_results] || true,
      allow_review: params[:allow_review] || true,
      require_proctoring: params[:require_proctoring] || false,
      # Fixed duplicate line
      instructions: params[:instructions],
      resources: params[:resources],
      rubric: params[:rubric],
      tags: params[:tags] || [],
      metadata: params[:metadata] || {}
    )
  end
end
