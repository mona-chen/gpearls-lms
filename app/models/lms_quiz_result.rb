# frozen_string_literal: true

class LmsQuizResult < ApplicationRecord
  # Associations
  belongs_to :quiz, class_name: "LmsQuiz", optional: false
  belongs_to :user, class_name: "User", optional: false
  belongs_to :batch, class_name: "Batch", optional: true
  
  has_many :quiz_submissions, dependent: :destroy
  has_many :quiz_question_results, dependent: :destroy
  
  # Validations
  validates :quiz, presence: true
  validates :user, presence: true
  validates :status, presence: true, inclusion: { in: %w[In Progress Submitted Evaluated Passed Failed Returned Resubmitted] }
  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: :max_score }, allow_nil: true
  validates :max_score, numericality: { greater_than: 0 }, allow_nil: true
  validates :percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :time_taken_seconds, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Scopes
  scope :in_progress, -> { where(status: "In Progress") }
  scope :submitted, -> { where(status: "Submitted") }
  scope :evaluated, -> { where(status: "Evaluated") }
  scope :passed, -> { where(status: "Passed") }
  scope :failed, -> { where(status: "Failed") }
  scope :returned, -> { where(status: "Returned") }
  scope :resubmitted, -> { where(status: "Resubmitted") }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_quiz, ->(quiz) { where(quiz: quiz) }
  scope :by_batch, ->(batch) { where(batch: batch) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :high_scorers, -> { where("score >= ?", 85) }
  scope :perfect_scores, -> { where("percentage >= ?", 95) }
  scope :failed_attempts, -> { where("score < ?", 40) }
  
  # Callbacks
  before_validation :set_default_values
  before_save :calculate_percentage_and_status
  after_save :update_user_progress
  
  # Instance Methods
  def in_progress?
    status == "In Progress"
  end
  
  def submitted?
    status == "Submitted"
  end
  
  def evaluated?
    status == "Evaluated"
  end
  
  def passed?
    status == "Passed" || status == "Evaluated" && percentage >= quiz.passing_percentage
  end
  
  def failed?
    status == "Failed" || status == "Evaluated" && percentage < quiz.passing_percentage
  end
  
  def returned?
    status == "Returned"
  end
  
  def resubmitted?
    status == "Resubmitted"
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
    return 0 if quiz_submissions.empty?
    
    total_score = 0
    quiz_submissions.each do |submission|
      next unless submission.correct?
      total_score += submission.question.marks
    end
    
    total_score
  end
  
  def calculate_max_score
    return 0 if quiz_submissions.empty?
    
    total_max_score = 0
    quiz_submissions.each do |submission|
      total_max_score += submission.question.marks
    end
    
    total_max_score
  end
  
  def get_correct_answers
    quiz_submissions.where(correct: true).includes(:question)
  end
  
  def get_incorrect_answers
    quiz_submissions.where(correct: false).includes(:question)
  end
  
  def get_answer_feedback(question_id)
    submission = quiz_submissions.find_by(question_id: question_id)
    return nil unless submission
    
    {
      answer: submission.answer,
      correct: submission.correct?,
      marks_obtained: submission.correct? ? submission.question.marks : 0,
      feedback: submission.feedback,
      time_taken: submission.time_taken_seconds
    }
  end
  
  def get_question_results
    quiz_submissions.includes(:question).map do |submission|
      {
        question_id: submission.question_id,
        question: submission.question.question,
        question_type: submission.question.question_type,
        marks_obtained: submission.correct? ? submission.question.marks : 0,
        max_marks: submission.question.marks,
        correct: submission.correct?,
        answer: submission.answer,
        feedback: submission.feedback,
        time_taken: submission.time_taken_seconds
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
      total_questions: quiz_submissions.count,
      correct_answers: quiz_submissions.where(correct: true).count,
      incorrect_answers: quiz_submissions.where(correct: false).count,
      accuracy: calculate_accuracy,
      grade: calculate_grade
    }
  end
  
  def to_frappe_format
    {
      id: id,
      quiz: quiz&.to_frappe_format,
      user: user&.to_frappe_format,
      batch: batch&.to_frappe_format,
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
      evaluator: evaluator&.to_frappe_format,
      evaluator_notes: evaluator_notes,
      quiz_submissions: quiz_submissions.map(&:to_frappe_format),
      performance_summary: get_performance_summary,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end
  
  # Class Methods
  def self.create_quiz_result(params)
    quiz_result = build_quiz_result_with_defaults(params)
    
    if quiz_result.save
      {
        success: true,
        quiz_result: quiz_result,
        message: "Quiz result created successfully"
      }
    else
      {
        success: false,
        error: "Failed to create quiz result",
        details: quiz_result.errors.full_messages
      }
    end
  end
  
  def self.get_user_quiz_results(user, options = {})
    results = user.quiz_results.includes(:quiz, :batch, :quiz_submissions)
    
    # Apply filters
    results = results.where(quiz: options[:quiz]) if options[:quiz].present?
    results = results.where(status: options[:status]) if options[:status].present?
    results = results.where(batch: options[:batch]) if options[:batch].present?
    
    # Apply sorting
    if options[:sort_by] == "score"
      results = results.order(score: :desc)
    elsif options[:sort_by] == "created_at"
      results = results.order(created_at: :desc)
    else
      results = results.order(created_at: :desc)
    end
    
    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    results = results.limit(limit).offset(offset)
    
    results.map(&:to_frappe_format)
  end
  
  def self.get_quiz_results(quiz, options = {})
    results = quiz.quiz_results.includes(:user, :batch, :quiz_submissions)
    
    # Apply filters
    results = results.where(status: options[:status]) if options[:status].present?
    results = results.where(batch: options[:batch]) if options[:batch].present?
    
    # Apply sorting
    if options[:sort_by] == "score"
      results = results.order(score: :desc)
    elsif options[:sort_by] == "created_at"
      results = results.order(created_at: :desc)
    else
      results = results.order(created_at: :desc)
    end
    
    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    results = results.limit(limit).offset(offset)
    
    results.map(&:to_frappe_format)
  end
  
  def self.get_batch_quiz_results(batch, options = {})
    results = batch.quiz_results.includes(:user, :quiz, :quiz_submissions)
    
    # Apply filters
    results = results.where(status: options[:status]) if options[:status].present?
    results = results.where(quiz: options[:quiz]) if options[:quiz].present?
    
    # Apply sorting
    results = results.order(created_at: :desc)
    
    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    results = results.limit(limit).offset(offset)
    
    results.map(&:to_frappe_format)
  end
  
  def self.get_evaluated_results(options = {})
    results = evaluated.includes(:user, :quiz, :batch, :quiz_submissions)
    
    # Apply filters
    results = results.where(quiz: options[:quiz]) if options[:quiz].present?
    results = results.where(batch: options[:batch]) if options[:batch].present?
    
    # Apply sorting
    results = results.order(score: :desc)
    
    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    results = results.limit(limit).offset(offset)
    
    results.map(&:to_frappe_format)
  end
  
  def self.get_results_by_status(status, options = {})
    results = where(status: status).includes(:user, :quiz, :batch, :quiz_submissions)
    
    # Apply filters
    results = results.where(quiz: options[:quiz]) if options[:quiz].present?
    results = results.where(batch: options[:batch]) if options[:batch].present?
    
    # Apply sorting
    results = results.order(created_at: :desc)
    
    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    results = results.limit(limit).offset(offset)
    
    results.map(&:to_frappe_format)
  end
  
  def self.get_results_by_score_range(min_score, max_score, options = {})
    results = where("score >= ? AND score <= ?", min_score, max_score)
             .includes(:user, :quiz, :batch, :quiz_submissions)
    
    # Apply sorting
    results = results.order(score: :desc)
    
    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    results = results.limit(limit).offset(offset)
    
    results.map(&:to_frappe_format)
  end
  
  def self.get_recent_results(options = {})
    results = recent.includes(:user, :quiz, :batch, :quiz_submissions)
    
    # Apply filters
    results = results.where(status: options[:status]) if options[:status].present?
    
    # Apply pagination
    limit = options[:limit] || 20
    results = results.limit(limit)
    
    results.map(&:to_frappe_format)
  end
  
  def self.get_top_performers(quiz, limit = 10)
    results = quiz.quiz_results
              .includes(:user)
              .where(status: "Evaluated")
              .order(score: :desc, percentage: :desc, time_taken_seconds: :asc)
              .limit(limit)
    
    performers = results.map do |result|
      {
        user: result.user.to_frappe_format,
        score: result.score,
        percentage: result.percentage,
        time_taken: result.time_taken_seconds,
        time_taken_formatted: result.time_taken_formatted,
        attempt_number: result.attempt_number,
        rank: nil, # Will be set below
      }
    end
    
    # Assign ranks
    performers.each_with_index do |performer, index|
      performer[:rank] = index + 1
    end
    
    {
      success: true,
      quiz: quiz.to_frappe_format,
      performers: performers,
      total: results.count
    }
  end
  
  def self.get_result_statistics(quiz_id)
    quiz = LmsQuiz.find_by(id: quiz_id)
    return { error: "Quiz not found" } unless quiz
    
    results = quiz.quiz_results.includes(:user, :quiz_submissions)
    
    {
      success: true,
      quiz_id: quiz_id,
      quiz_name: quiz.name,
      total_submissions: results.count,
      unique_users: results.count("user_id"),
      average_score: results.average(:score)&.round(2) || 0,
      average_time: results.average(:time_taken_seconds)&.round(2) || 0,
      highest_score: results.maximum(:score) || 0,
      lowest_score: results.minimum(:score) || 0,
      pass_rate: calculate_pass_rate(results, quiz),
      fail_rate: calculate_fail_rate(results, quiz),
      score_distribution: get_score_distribution(results),
      time_distribution: get_time_distribution(results),
      daily_submissions: get_daily_submissions(results),
      user_performance: get_user_performance(results),
      attempt_statistics: get_attempt_statistics(results)
    }
  end
  
  def self.get_user_performance_over_time(user, quiz, options = {})
    results = user.quiz_results
              .where(quiz: quiz)
              .includes(:quiz_submissions)
              .order(:created_at)
    
    performance_over_time = results.map do |result|
      {
        attempt_number: result.attempt_number,
        score: result.score,
        percentage: result.percentage,
        time_taken: result.time_taken_seconds,
        submitted_at: result.submitted_at&.iso8601,
        improvement: calculate_improvement(result, results)
      }
    end
    
    performance_over_time
  end
  
  private
  
  def set_default_values
    self.status ||= "In Progress"
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
      if quiz && percentage && quiz.passing_percentage
        self.status = if percentage >= quiz.passing_percentage
          "Passed"
        else
          "Failed"
        end
      end
    end
  end
  
  def update_user_progress
    return unless user && quiz && batch
    
    # Update course progress based on quiz performance
    if passed?
      # Mock progress update - in real implementation, this would call CourseProgress service
      # CourseProgressService.update_progress_for_quiz(user, quiz, batch, self)
    end
  end
  
  def calculate_accuracy
    return 0 if quiz_submissions.empty?
    
    correct_count = quiz_submissions.where(correct: true).count
    total_count = quiz_submissions.count
    
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
  
  def calculate_pass_rate(results, quiz)
    return 0 if results.empty?
    
    passing_count = results.select { |result| result.passed? }.count
    (passing_count.to_f / results.count * 100).round(2)
  end
  
  def calculate_fail_rate(results, quiz)
    return 0 if results.empty?
    
    failing_count = results.select { |result| result.failed? }.count
    (failing_count.to_f / results.count * 100).round(2)
  end
  
  def get_score_distribution(results)
    return {} if results.empty?
    
    ranges = {
      "0-59" => 0,
      "60-69" => 0,
      "70-79" => 0,
      "80-89" => 0,
      "90-100" => 0
    }
    
    results.each do |result|
      percentage = result.percentage || 0
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
  
  def get_time_distribution(results)
    return {} if results.empty?
    
    ranges = {
      "0-5 min" => 0,
      "5-10 min" => 0,
      "10-20 min" => 0,
      "20-30 min" => 0,
      "30+ min" => 0
    }
    
    results.each do |result|
      time_minutes = (result.time_taken_seconds || 0) / 60
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
  
  def get_daily_submissions(results)
    return {} if results.empty?
    
    daily_counts = results.group_by_day(:submitted_at).count
    daily_counts.transform_keys(&:to_s)
  end
  
  def get_user_performance(results)
    return {} if results.empty?
    
    user_performance = {}
    results.group_by(&:user).each do |user, user_results|
      user_performance[user.email] = {
        attempts: user_results.count,
        best_score: user_results.maximum(:score) || 0,
        average_score: user_results.average(:score)&.round(2) || 0,
        best_percentage: user_results.maximum(:percentage) || 0,
        average_percentage: user_results.average(:percentage)&.round(2) || 0,
        passed: user_results.select(&:passed?).count,
        failed: user_results.select(&:failed?).count,
        total_time: user_results.sum(:time_taken_seconds) || 0,
        improvement_trend: calculate_improvement_trend(user_results)
      }
    end
    
    user_performance
  end
  
  def get_attempt_statistics(results)
    return {} if results.empty?
    
    attempt_stats = {
      single_attempt: results.where(attempt_number: 1).count,
      multiple_attempts: results.where("attempt_number > 1").count,
      average_attempts: results.average(:attempt_number)&.round(2) || 0,
      max_attempts: results.maximum(:attempt_number) || 0
    }
    
    # Performance by attempt number
    (1..(attempt_stats[:max_attempts] || 1)).each do |attempt_num|
      attempt_submissions = results.where(attempt_number: attempt_num)
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
  
  def calculate_improvement(result, all_results)
    previous_attempts = all_results.where("created_at < ?", result.created_at).where(user: result.user, quiz: result.quiz)
    return 0 if previous_attempts.empty?
    
    previous_average = previous_attempts.average(:score) || 0
    improvement = result.score - previous_average
    
    improvement.round(2)
  end
  
  def calculate_improvement_trend(user_results)
    return 0 if user_results.length <= 1
    
    sorted_results = user_results.sort_by(:created_at)
    improvements = []
    
    sorted_results.each_with_index do |result, index|
      next if index == 0
      previous_score = sorted_results[index - 1].score
      improvement = result.score - previous_score
      improvements << improvement
    end
    
    return 0 if improvements.empty?
    
    improvements.sum / improvements.length.round(2)
  end
  
  private
  
  def build_quiz_result_with_defaults(params)
    LmsQuizResult.new(
      quiz: params[:quiz],
      user: params[:user],
      batch: params[:batch],
      attempt_number: params[:attempt_number] || 1,
      status: params[:status] || "In Progress",
      score: params[:score] || 0,
      max_score: params[:max_score] || 0,
      percentage: params[:percentage] || 0,
      time_taken_seconds: params[:time_taken_seconds] || 0,
      start_time: params[:start_time],
      end_time: params[:end_time],
      submitted_at: params[:submitted_at],
      evaluated_at: params[:evaluated_at],
      evaluator: params[:evaluator],
      evaluator_notes: params[:evaluator_notes]
    )
  end
end
