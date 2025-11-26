# frozen_string_literal: true

class LmsAssessmentSubmission < ApplicationRecord
  # Associations
  belongs_to :assessment, class_name: "LmsAssessment", optional: false
  belongs_to :user, class_name: "User", optional: false
  belongs_to :batch, class_name: "Batch", optional: true
  belongs_to :assessment_attempt, class_name: "AssessmentAttempt", optional: true
  belongs_to :evaluator, class_name: "User", optional: true

  has_many :assessment_questions, dependent: :destroy
  has_many :assessment_evaluations, dependent: :destroy
  has_many :assessment_attempts, dependent: :destroy
  has_many :submission_files, dependent: :destroy

  # Validations
  validates :assessment, presence: true
  validates :user, presence: true
  validates :status, presence: true, inclusion: { in: %w[Draft Submitted Evaluated Passed Failed Returned Resubmitted Under Review] }
  validates :max_score, numericality: { greater_than: 0 }, allow_nil: true
  validates :percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :time_taken_seconds, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :attempt_number, numericality: { greater_than: 0, integer_only: true }, allow_nil: true

  # Scopes
  scope :draft, -> { where(status: "Draft") }
  scope :submitted, -> { where(status: "Submitted") }
  scope :evaluated, -> { where(status: "Evaluated") }
  scope :passed, -> { where(status: "Passed") }
  scope :failed, -> { where(status: "Failed") }
  scope :returned, -> { where(status: "Returned") }
  scope :resubmitted, -> { where(status: "Resubmitted") }
  scope :under_review, -> { where(status: "Under Review") }
  scope :by_assessment, ->(assessment) { where(assessment: assessment) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_batch, ->(batch) { where(batch: batch) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :high_scorers, -> { where("score >= ?", 80) }
  scope :perfect_scores, -> { where("percentage >= ?", 95) }
  scope :failed_attempts, -> { where("score < ?", 40) }

  # Callbacks
  before_validation :set_default_values
  before_save :calculate_percentage_and_status
  after_save :update_user_progress
  after_save :trigger_badge_awards

  # Instance Methods
  def draft?
    status == "Draft"
  end

  def submitted?
    status == "Submitted"
  end

  def evaluated?
    status == "Evaluated"
  end

  def passed?
    status == "Passed" || status == "Evaluated" && percentage >= assessment.passing_percentage
  end

  def failed?
    status == "Failed" || status == "Evaluated" && percentage < assessment.passing_percentage
  end

  def returned?
    status == "Returned"
  end

  def resubmitted?
    status == "Resubmitted"
  end

  def under_review?
    status == "Under Review"
  end

  def complete?
    submitted? || evaluated? || passed? || failed?
  end

  def time_taken_formatted
    return "0 seconds" if time_taken_seconds.nil? || time_taken_seconds.zero?

    hours = time_taken_seconds / 3600
    minutes = (time_taken_seconds % 3600) / 60
    seconds = time_taken_seconds % 60

    parts = []
    parts << "#{hours} hour#{s if hours > 1}" if hours > 0
    parts << "#{hours} hour" if hours == 1
    parts << "#{minutes} minute#{s if minutes > 0}" if minutes > 0
    parts << "#{minutes} minute" if minutes == 1
    parts << "#{seconds} second#{s if seconds > 0}" if seconds > 0
    parts << "#{seconds} second" if seconds == 1

    parts.join(" ")
  end

  def calculate_score
    return 0 if assessment_questions.empty?

    total_score = 0
    assessment_questions.each do |question|
      total_score += question.score || 0
    end

    total_score
  end

  def calculate_max_score
    return 0 if assessment_questions.empty?

    total_max_score = 0
    assessment_questions.each do |question|
      total_max_score += question.max_marks || question.question.marks
    end

    total_max_score
  end

  def get_correct_answers
    assessment_questions.where(correct: true).includes(:question)
  end

  def get_incorrect_answers
    assessment_questions.where(correct: false).includes(:question)
  end

  def get_question_results
    assessment_questions.includes(:question).map do |question|
      {
        question_id: question.question_id,
        question: question.question.question,
        question_type: question.question.question_type,
        marks_obtained: question.score || 0,
        max_marks: question.max_marks || question.question.marks,
        correct: question.correct?,
        answer: question.answer,
        feedback: question.feedback,
        time_taken: question.time_taken_seconds
      }
    end
  end

  def get_performance_summary
    return {} unless submitted? || evaluated?

    {
      score: score,
      max_score: max_score,
      percentage: percentage,
      time_taken: time_taken_seconds,
      time_taken_formatted: time_taken_formatted,
      total_questions: assessment_questions.count,
      correct_answers: assessment_questions.where(correct: true).count,
      incorrect_answers: assessment_questions.where(correct: false).count,
      accuracy: calculate_accuracy,
      grade: calculate_grade,
      attempt_number: attempt_number
    }
  end

  def get_submission_files
    submission_files.includes(:file)
  end

  def get_evaluations
    assessment_evaluations.includes(:evaluator)
  end

  def to_frappe_format
    {
      id: id,
      assessment: assessment&.to_frappe_format,
      user: user&.to_frappe_format,
      batch: batch&.to_frappe_format,
      assessment_attempt: assessment_attempt&.to_frappe_format,
      evaluator: evaluator&.to_frappe_format,
      attempt_number: attempt_number,
      status: status,
      score: score,
      max_score: max_score,
      percentage: percentage,
      time_taken_seconds: time_taken_seconds,
      time_taken_formatted: time_taken_formatted,
      start_time: start_time&.iso8601,
      end_time: end_time&.iso8601,
      submitted_at: submitted_at&.iso8601,
      evaluated_at: evaluated_at&.iso8601,
      evaluator_notes: evaluator_notes,
      assessment_questions: assessment_questions.map(&:to_frappe_format),
      submission_files: get_submission_files.map(&:to_frappe_format),
      evaluations: get_evaluations.map(&:to_frappe_format),
      performance_summary: get_performance_summary,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end

  # Class Methods
  def self.create_submission(params)
    submission = build_submission_with_defaults(params)

    if submission.save
      {
        success: true,
        submission: submission,
        message: "Assessment submission created successfully"
      }
    else
      {
        success: false,
        error: "Failed to create assessment submission",
        details: submission.errors.full_messages
      }
    end
  end

  def self.get_user_submissions(user, options = {})
    submissions = user.assessment_submissions.includes(:assessment, :batch, :assessment_questions)

    # Apply filters
    submissions = submissions.where(assessment: options[:assessment]) if options[:assessment].present?
    submissions = submissions.where(status: options[:status]) if options[:status].present?
    submissions = submissions.where(batch: options[:batch]) if options[:batch].present?

    # Apply sorting
    if options[:sort_by] == "score"
      submissions = submissions.order(score: :desc)
    elsif options[:sort_by] == "created_at"
      submissions = submissions.order(created_at: :desc)
    else
      submissions = submissions.order(created_at: :desc)
    end

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    submissions = submissions.limit(limit).offset(offset)

    submissions.map(&:to_frappe_format)
  end

  def self.get_assessment_submissions(assessment, options = {})
    submissions = assessment.assessment_submissions.includes(:user, :batch, :assessment_questions)

    # Apply filters
    submissions = submissions.where(status: options[:status]) if options[:status].present?
    submissions = submissions.where(batch: options[:batch]) if options[:batch].present?

    # Apply sorting
    if options[:sort_by] == "score"
      submissions = submissions.order(score: :desc)
    elsif options[:sort_by] == "created_at"
      submissions = submissions.order(created_at: :desc)
    else
      submissions = submissions.order(created_at: :desc)
    end

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    submissions = submissions.limit(limit).offset(offset)

    submissions.map(&:to_frappe_format)
  end

  def self.get_batch_submissions(batch, options = {})
    submissions = batch.assessment_submissions.includes(:user, :assessment, :assessment_questions)

    # Apply filters
    submissions = submissions.where(status: options[:status]) if options[:status].present?
    submissions = submissions.where(assessment: options[:assessment]) if options[:assessment].present?

    # Apply sorting
    submissions = submissions.order(created_at: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    submissions = submissions.limit(limit).offset(offset)

    submissions.map(&:to_frappe_format)
  end

  def self.get_evaluated_submissions(options = {})
    submissions = evaluated.includes(:user, :assessment, :batch, :assessment_questions, :evaluator)

    # Apply filters
    submissions = submissions.where(assessment: options[:assessment]) if options[:assessment].present?
    submissions = submissions.where(batch: options[:batch]) if options[:batch].present?

    # Apply sorting
    submissions = submissions.order(score: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    submissions = submissions.limit(limit).offset(offset)

    submissions.map(&:to_frappe_format)
  end

  def self.get_submissions_by_status(status, options = {})
    submissions = where(status: status).includes(:user, :assessment, :batch, :assessment_questions)

    # Apply filters
    submissions = submissions.where(assessment: options[:assessment]) if options[:assessment].present?
    submissions = submissions.where(batch: options[:batch]) if options[:batch].present?

    # Apply sorting
    submissions = submissions.order(created_at: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    submissions = submissions.limit(limit).offset(offset)

    submissions.map(&:to_frappe_format)
  end

  def self.get_submissions_by_score_range(min_score, max_score, options = {})
    submissions = where("score >= ? AND score <= ?", min_score, max_score)
             .includes(:user, :assessment, :batch, :assessment_questions)

    # Apply sorting
    submissions = submissions.order(score: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    submissions = submissions.limit(limit).offset(offset)

    submissions.map(&:to_frappe_format)
  end

  def self.get_recent_submissions(options = {})
    submissions = recent.includes(:user, :assessment, :batch, :assessment_questions)

    # Apply filters
    submissions = submissions.where(status: options[:status]) if options[:status].present?

    # Apply pagination
    limit = options[:limit] || 20
    submissions = submissions.limit(limit)

    submissions.map(&:to_frappe_format)
  end

  def self.get_top_performers(assessment, limit = 10)
    submissions = assessment.assessment_submissions
                  .includes(:user)
                  .where(status: "Evaluated")
                  .order(score: :desc, percentage: :desc, time_taken_seconds: :asc)
                  .limit(limit)

    performers = submissions.map do |submission|
      {
        user: submission.user.to_frappe_format,
        score: submission.score,
        percentage: submission.percentage,
        time_taken: submission.time_taken_seconds,
        time_taken_formatted: submission.time_taken_formatted,
        attempt_number: submission.attempt_number,
        grade: submission.calculate_grade,
        rank: nil # Will be set below
      }
    end

    # Assign ranks
    performers.each_with_index do |performer, index|
      performer[:rank] = index + 1
    end

    {
      success: true,
      assessment: assessment.to_frappe_format,
      performers: performers,
      total: submissions.count
    }
  end

  def self.get_submission_statistics(submission_id)
    submission = find_by(id: submission_id)
    return { error: "Submission not found" } unless submission

    {
      success: true,
      submission_id: submission_id,
      assessment: submission.assessment.to_frappe_format,
      user: submission.user.to_frappe_format,
      attempt_number: submission.attempt_number,
      status: submission.status,
      score: submission.score,
      max_score: submission.max_score,
      percentage: submission.percentage,
      time_taken: submission.time_taken_seconds,
      submitted_at: submission.submitted_at&.iso8601,
      evaluated_at: submission.evaluated_at&.iso8601,
      evaluator: submission.evaluator&.to_frappe_format,
      evaluator_notes: submission.evaluator_notes,
      performance_summary: submission.get_performance_summary
    }
  end

  def self.bulk_grade_submissions(submissions, evaluator, options = {})
    graded_count = 0
    failed_count = 0
    results = []

    submissions.each do |submission|
      begin
        # Calculate scores and evaluate submission
        submission.score = submission.calculate_score
        submission.max_score = submission.calculate_max_score
        submission.percentage = submission.max_score > 0 ? (submission.score.to_f / submission.max_score.to_f * 100).round(2) : 0

        # Update status based on passing criteria
        if submission.assessment.passing_marks && submission.score >= submission.assessment.passing_marks
          submission.status = "Passed"
        else
          submission.status = "Failed"
        end

        submission.evaluator = evaluator
        submission.evaluated_at = Time.current

        if submission.save
          graded_count += 1
          results << {
            submission_id: submission.id,
            success: true,
            score: submission.score,
            percentage: submission.percentage,
            status: submission.status
          }
        else
          failed_count += 1
          results << {
            submission_id: submission.id,
            success: false,
            error: submission.errors.full_messages
          }
        end
      rescue => e
        failed_count += 1
        results << {
          submission_id: submission.id,
          success: false,
          error: e.message
        }
      end
    end

    {
      success: true,
      graded_count: graded_count,
      failed_count: failed_count,
      results: results
    }
  end

  private

  def set_default_values
    self.status ||= "Draft"
    self.score ||= 0
    self.max_score ||= 0
    self.percentage ||= 0
    self.time_taken_seconds ||= 0
    self.attempt_number ||= 1
  end

  def calculate_percentage_and_status
    if max_score && max_score > 0 && score
      self.percentage = (score.to_f / max_score.to_f * 100).round(2)
    end

    if status == "Submitted" || status == "Evaluated"
      if assessment && assessment.passing_marks && score >= assessment.passing_marks
        self.status = "Passed"
      else
        self.status = "Failed"
      end
    end
  end

  def update_user_progress
    return unless user && assessment && batch

    # Update course progress based on assessment performance
    if passed?
      # Mock progress update - in real implementation, this would call CourseProgress service
      # CourseProgressService.update_progress_for_assessment(user, assessment, batch, self)
    end
  end

  def trigger_badge_awards
    nil unless user && passed?

    # Mock badge awarding - in real implementation, this would call BadgeService
    # BadgeService.check_and_award_badge(user, "Assessment Completed", self)
  end

  def calculate_accuracy
    return 0 if assessment_questions.empty?

    correct_count = assessment_questions.where(correct: true).count
    total_count = assessment_questions.count

    return 0 if total_count.zero?

    (correct_count.to_f / total_count * 100).round(2)
  end

  def calculate_grade
    return "F" unless percentage

    case percentage
    when 90..100
      "A+"
    when 85..89
      "A"
    when 80..84
      "B+"
    when 75..79
      "B"
    when 70..74
      "C+"
    when 65..69
      "C"
    when 60..64
      "D"
    else
      "F"
    end
  end

  private

  def build_submission_with_defaults(params)
    LmsAssessmentSubmission.new(
      assessment: params[:assessment],
      user: params[:user],
      batch: params[:batch],
      assessment_attempt: params[:assessment_attempt],
      attempt_number: params[:attempt_number] || 1,
      status: params[:status] || "Draft",
      score: params[:score] || 0,
      max_score: params[:max_score] || 0,
      percentage: params[:percentage] || 0,
      time_taken_seconds: params[:time_taken_seconds] || 0,
      start_time: params[:start_time],
      end_time: params[:end_time],
      submitted_at: params[:submitted_at],
      evaluated_at: params[:evaluated_at],
      evaluator: params[:evaluator],
      evaluator_notes: params[:evaluator_notes],
      submission_data: params[:submission_data] || {}
    )
  end
end
