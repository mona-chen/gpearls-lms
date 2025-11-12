# frozen_string_literal: true

class LmsQuizSubmission < ApplicationRecord
  # Associations
  belongs_to :quiz_result, class_name: "LmsQuizResult", optional: false
  belongs_to :question, class_name: "LmsQuestion", optional: false
  belongs_to :quiz_question, class_name: "QuizQuestion", optional: true
  
  # Validations
  validates :quiz_result, presence: true
  validates :question, presence: true
  validates :answer, presence: true
  validates :correct, inclusion: { in: [true, false] }
  validates :time_taken_seconds, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Scopes
  scope :correct, -> { where(correct: true) }
  scope :incorrect, -> { where(correct: false) }
  scope :by_quiz_result, ->(quiz_result) { where(quiz_result: quiz_result) }
  scope :by_question, ->(question) { where(question: question) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Callbacks
  before_validation :set_default_values
  after_save :update_quiz_result_score
  
  # Instance Methods
  def correct?
    correct
  end
  
  def incorrect?
    !correct
  end
  
  def max_marks
    question.marks
  end
  
  def question_marks
    question.marks
  end
  
  def get_feedback
    {
      answer: answer,
      correct: correct,
      marks_obtained: correct ? question.marks : 0,
      max_marks: question.marks,
      feedback: feedback,
      time_taken: time_taken_seconds
    }
  end
  
  def to_frappe_format
    {
      id: id,
      quiz_result: quiz_result&.to_frappe_format,
      question: question&.to_frappe_format,
      quiz_question: quiz_question&.to_frappe_format,
      answer: answer,
      correct: correct,
      marks_obtained: marks_obtained,
      max_marks: max_marks,
      feedback: feedback,
      time_taken_seconds: time_taken_seconds,
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
        message: "Quiz submission created successfully"
      }
    else
      {
        success: false,
        error: "Failed to create quiz submission",
        details: submission.errors.full_messages
      }
    end
  end
  
  def self.get_submissions_for_quiz_result(quiz_result)
    quiz_result.quiz_submissions.includes(:question, :quiz_question)
                 .order(:question_id)
                 .map(&:to_frappe_format)
  end
  
  def self.get_submissions_for_question(question, options = {})
    submissions = question.quiz_submissions.includes(:quiz_result, :quiz_question)
    
    # Apply filters
    submissions = submissions.where(quiz_result: options[:quiz_result]) if options[:quiz_result].present?
    submissions = submissions.where(correct: options[:correct]) if options[:correct].present?
    
    # Apply sorting
    submissions = submissions.order(created_at: :desc)
    
    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    submissions = submissions.limit(limit).offset(offset)
    
    submissions.map(&:to_frappe_format)
  end
  
  def self.get_correct_submissions(options = {})
    submissions = correct.includes(:question, :quiz_result, :quiz_question)
    
    # Apply filters
    submissions = submissions.where(question: options[:question]) if options[:question].present?
    submissions = submissions.where(quiz_result: options[:quiz_result]) if options[:quiz_result].present?
    
    # Apply sorting
    submissions = submissions.order(created_at: :desc)
    
    submissions.map(&:to_frappe_format)
  end
  
  def self.get_incorrect_submissions(options = {})
    submissions = incorrect.includes(:question, :quiz_result, :quiz_question)
    
    # Apply filters
    submissions = submissions.where(question: options[:question]) if options[:question].present?
    submissions = submissions.where(quiz_result: options[:quiz_result]) if options[:quiz_result].present?
    
    # Apply sorting
    submissions = submissions.order(created_at: :desc)
    
    submissions.map(&:to_frappe_format)
  end
  
  def self.get_submission_statistics(submission_id)
    submission = find_by(id: submission_id)
    return { error: "Submission not found" } unless submission
    
    {
      success: true,
      submission_id: submission_id,
      question: submission.question.to_frappe_format,
      quiz_result: submission.quiz_result.to_frappe_format,
      answer: submission.answer,
      correct: submission.correct,
      marks_obtained: submission.marks_obtained,
      max_marks: submission.max_marks,
      time_taken: submission.time_taken_seconds,
      feedback: submission.feedback,
      created_at: submission.created_at&.iso8601
    }
  end
  
  def self.get_question_performance(question_id)
    question = LmsQuestion.find_by(id: question_id)
    return { error: "Question not found" } unless question
    
    submissions = question.quiz_submissions.includes(:quiz_result)
    
    {
      success: true,
      question_id: question_id,
      question: question.to_frappe_format,
      total_submissions: submissions.count,
      correct_submissions: submissions.where(correct: true).count,
      incorrect_submissions: submissions.where(correct: false).count,
      accuracy_rate: calculate_accuracy_rate(submissions),
      average_marks_obtained: submissions.average(:marks_obtained)&.round(2) || 0,
      average_time_taken: submissions.average(:time_taken_seconds)&.round(2) || 0,
      difficulty_distribution: get_difficulty_distribution(submissions),
      submission_distribution: get_submission_distribution(submissions)
    }
  end
  
  def self.bulk_grade_submissions(submissions, evaluator, options = {})
    graded_count = 0
    failed_count = 0
    results = []
    
    submissions.each do |submission|
      begin
        # Evaluate submission based on correct answer
        is_correct = evaluate_submission_correctness(submission)
        marks_obtained = is_correct ? submission.question.marks : 0
        
        submission.update!(
          correct: is_correct,
          marks_obtained: marks_obtained,
          feedback: generate_feedback(submission, is_correct, evaluator, options)
        )
        
        graded_count += 1
        results << {
          submission_id: submission.id,
          success: true,
          correct: is_correct,
          marks_obtained: marks_obtained
        }
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
    self.correct ||= false
    self.marks_obtained ||= 0
    self.time_taken_seconds ||= 0
  end
  
  def update_quiz_result_score
    return unless quiz_result && quiz_result.submitted? || quiz_result.evaluated?
    
    # Update quiz result scores when a submission is graded
    submissions = quiz_result.quiz_submissions.includes(:question)
    
    total_score = 0
    total_max_score = 0
    
    submissions.each do |submission|
      total_score += submission.marks_obtained.to_i
      total_max_score += submission.question.marks.to_i
    end
    
    total_percentage = total_max_score > 0 ? (total_score.to_f / total_max_score.to_f * 100).round(2) : 0
    
    quiz_result.update!(
      score: total_score,
      max_score: total_max_score,
      percentage: total_percentage
    )
  end
  
  def evaluate_submission_correctness(submission)
    # For multiple choice questions, compare with correct answer
    if submission.question.multiple_choice?
      return submission.answer == submission.question.correct_answer
    end
    
    # For true/false questions
    if submission.question.true_false?
      return submission.answer.downcase == submission.question.correct_answer.downcase
    end
    
    # For short answer and essay questions, this would require manual evaluation
    if submission.question.short_answer? || submission.question.essay?
      return submission.correct # Assume already evaluated
    end
    
    # For coding questions, this would require test execution
    if submission.question.coding?
      return submission.correct # Assume already evaluated
    end
    
    # Default to false for other types
    false
  end
  
  def generate_feedback(submission, is_correct, evaluator, options)
    feedback_parts = []
    
    if is_correct
      feedback_parts << "Correct! Well done."
      feedback_parts << "Marks obtained: #{submission.marks_obtained}/#{submission.max_marks}"
    else
      feedback_parts << "Incorrect answer."
      feedback_parts << "The correct answer was: #{submission.question.correct_answer}"
      feedback_parts << "Marks obtained: 0/#{submission.max_marks}"
    end
    
    feedback_parts << "Time taken: #{submission.time_taken_seconds} seconds"
    
    if evaluator && evaluator.name
      feedback_parts << "Evaluated by: #{evaluator.name}"
    end
    
    feedback_parts.join(" ")
  end
  
  def calculate_accuracy_rate(submissions)
    return 0 if submissions.empty?
    
    correct_count = submissions.where(correct: true).count
    total_count = submissions.count
    
    return 0 if total_count.zero?
    
    (correct_count.to_f / total_count * 100).round(2)
  end
  
  def get_difficulty_distribution(submissions)
    return {} if submissions.empty?
    
    distribution = {
      "Easy" => 0,
      "Medium" => 0,
      "Hard" => 0
    }
    
    submissions.each do |submission|
      difficulty = submission.question.difficulty_level
      distribution[difficulty] += 1 if distribution.key?(difficulty)
    end
    
    distribution
  end
  
  def get_submission_distribution(submissions)
    return {} if submissions.empty?
    
    distribution = {
      "In Progress" => 0,
      "Submitted" => 0,
      "Evaluated" => 0
    }
    
    submissions.each do |submission|
      status = submission.quiz_result&.status || "In Progress"
      distribution[status] += 1 if distribution.key?(status)
    end
    
    distribution
  end
  
  private
  
  def build_submission_with_defaults(params)
    LmsQuizSubmission.new(
      quiz_result: params[:quiz_result],
      question: params[:question],
      quiz_question: params[:quiz_question],
      answer: params[:answer],
      correct: params[:correct] || false,
      marks_obtained: params[:marks_obtained] || 0,
      feedback: params[:feedback],
      time_taken_seconds: params[:time_taken_seconds] || 0
    )
  end
end
