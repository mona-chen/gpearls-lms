# frozen_string_literal: true

class LmsQuestion < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: "User", optional: true
  has_many :quiz_questions, dependent: :destroy
  has_many :assessment_questions, dependent: :destroy
  has_many :question_attempts, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :question, presence: true
  # validates :question_type, presence: true, inclusion: { in: %w[Multiple Choice True False Short Answer Essay Fill in the Blank Matching Coding] }
  validates :marks, presence: true, numericality: { greater_than: 0 }
  # These fields don't exist in database - removing validations
  # validates :difficulty_level, presence: true, inclusion: { in: %w[Easy Medium Hard] }
  # validates :category, presence: true
  # validates :status, presence: true, inclusion: { in: %w[Active Inactive Archived] }

  # Scopes - status field doesn't exist in database, removing these scopes
  # scope :active, -> { where(status: "Active") }
  # scope :inactive, -> { where(status: "Inactive") }
  # scope :archived, -> { where(status: "Archived") }
  scope :by_type, ->(type) { where(question_type: type) }
  scope :by_difficulty, ->(difficulty) { where(difficulty_level: difficulty) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_owner, ->(owner) { where(owner: owner) }
  scope :multiple_choice, -> { where(question_type: "Multiple Choice") }
  scope :true_false, -> { where(question_type: "True False") }
  scope :short_answer, -> { where(question_type: "Short Answer") }
  scope :essay, -> { where(question_type: "Essay") }

  # Callbacks
  before_validation :set_default_values

  # Instance Methods - status field doesn't exist, removing these methods
  # def active?
  #   status == "Active"
  # end

  # def inactive?
  #   status == "Inactive"
  # end

  # def archived?
  #   status == "Archived"
  # end

  def multiple_choice?
    question_type == "Multiple Choice"
  end

  def true_false?
    question_type == "True False"
  end

  def short_answer?
    question_type == "Short Answer"
  end

  def essay?
    question_type == "Essay"
  end

  def coding?
    question_type == "Coding"
  end

  def has_options?
    multiple_choice? || true_false? || matching?
  end

  def has_text_answer?
    short_answer? || essay? || fill_in_the_blank?
  end

  def has_code_answer?
    coding?
  end

  def to_frappe_format
    {
      name: name,
      question: question,
      question_type: question_type,
      marks: marks,
      difficulty_level: difficulty_level,
      category: category,
      status: status,
      owner: owner&.email,
      option_1: option_1,
      option_2: option_2,
      option_3: option_3,
      option_4: option_4,
      option_5: option_5,
      correct_answer: correct_answer,
      explanation: explanation,
      tags: tags,
      is_public: is_public,
      usage_count: quiz_questions.count + assessment_questions.count,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end

  # Class Methods
  def self.create_question(params)
    question = build_question_with_defaults(params)

    if question.save
      {
        success: true,
        question: question,
        message: "Question created successfully"
      }
    else
      {
        success: false,
        error: "Failed to create question",
        details: question.errors.full_messages
      }
    end
  end

  def self.get_questions(options = {})
    questions = includes(:owner, :quiz_questions, :assessment_questions)

    # Apply filters
    questions = questions.where(status: options[:status]) if options[:status].present?
    questions = questions.where(question_type: options[:question_type]) if options[:question_type].present?
    questions = questions.where(difficulty_level: options[:difficulty]) if options[:difficulty].present?
    questions = questions.where(category: options[:category]) if options[:category].present?
    questions = questions.where(owner: options[:owner]) if options[:owner].present?

    # Apply sorting
    if options[:sort_by] == "name"
      questions = questions.order(:name)
    elsif options[:sort_by] == "difficulty"
      questions = questions.order("CASE difficulty_level WHEN \"Easy\" THEN 1 WHEN \"Medium\" THEN 2 WHEN \"Hard\" THEN 3 END")
    elsif options[:sort_by] == "marks"
      questions = questions.order(marks: :desc)
    elsif options[:sort_by] == "created_at"
      questions = questions.order(created_at: :desc)
    else
      questions = questions.order(created_at: :desc)
    end

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    questions = questions.limit(limit).offset(offset)

    questions.map(&:to_frappe_format)
  end

  def self.get_user_questions(user, options = {})
    get_questions(options.merge(owner: user))
  end

  def self.get_questions_by_type(question_type, options = {})
    get_questions(options.merge(question_type: question_type))
  end

  def self.get_questions_by_difficulty(difficulty, options = {})
    get_questions(options.merge(difficulty: difficulty))
  end

  def self.get_questions_by_category(category, options = {})
    get_questions(options.merge(category: category))
  end

  def self.search_questions(search_term, options = {})
    return [] if search_term.blank?

    questions = where("name ILIKE ? OR question ILIKE ? OR category ILIKE ? OR tags ILIKE ?",
                    "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%")
             .includes(:owner, :quiz_questions, :assessment_questions)

    # Apply filters
    questions = questions.where(status: options[:status]) if options[:status].present?
    questions = questions.where(question_type: options[:question_type]) if options[:question_type].present?

    # Apply sorting
    questions = questions.order(created_at: :desc)

    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    questions = questions.limit(limit).offset(offset)

    questions.map(&:to_frappe_format)
  end

  def self.get_question_statistics(question_id)
    question = find_by(id: question_id)
    return { error: "Question not found" } unless question

    quiz_questions = question.quiz_questions.includes(:quiz)
    assessment_questions = question.assessment_questions.includes(:assessment)

    {
      success: true,
      question_id: question_id,
      question_name: question.name,
      question_type: question.question_type,
      marks: question.marks,
      difficulty_level: question.difficulty_level,
      category: question.category,
      quiz_usage_count: quiz_questions.count,
      assessment_usage_count: assessment_questions.count,
      total_usage_count: quiz_questions.count + assessment_questions.count,
      average_score_in_quizzes: calculate_average_score_in_quizzes(quiz_questions),
      average_score_in_assessments: calculate_average_score_in_assessments(assessment_questions),
      most_used_in: get_most_used_in(question),
      usage_by_difficulty: get_usage_by_difficulty(question)
    }
  end

  def self.duplicate_question(original_question, new_name, options = {})
    return { error: "Original question not found" } unless original_question

    # Create new question with duplicated properties
    new_question = original_question.dup
    new_question.name = new_name
    new_question.question = "#{original_question.question} (Copy)"
    new_question.status = "Draft"

    if new_question.save
      {
        success: true,
        question: new_question,
        message: "Question duplicated successfully"
      }
    else
      {
        success: false,
        error: "Failed to duplicate question",
        details: new_question.errors.full_messages
      }
    end
  end

  private

  def set_default_values
    # These fields don't exist in database - removing defaults
    # self.status ||= "Active"
    # self.difficulty_level ||= "Medium"
    # self.category ||= "General"
    # self.is_public ||= true
  end

  def calculate_average_score_in_quizzes(quiz_questions)
    return 0 if quiz_questions.empty?

    total_scores = quiz_questions.joins(:quiz_results)
                   .where(quiz_results.score IS NOT NULL)
                   .sum(quiz_results.score)

    total_possible = quiz_questions.joins(:quiz_results)
                       .where(quiz_results.max_score IS NOT NULL)
                       .sum(quiz_results.max_score)

    return 0 if total_possible.zero?

    (total_scores.to_f / total_possible * 100).round(2)
  end

  def calculate_average_score_in_assessments(assessment_questions)
    return 0 if assessment_questions.empty?

    total_scores = assessment_questions.joins(:assessment_submissions)
                   .where(assessment_submissions.score IS NOT NULL)
                   .sum(assessment_submissions.score)

    total_possible = assessment_questions.joins(:assessment_submissions)
                       .where(assessment_submissions.max_score IS NOT NULL)
                       .sum(assessment_submissions.max_score)

    return 0 if total_possible.zero?

    (total_scores.to_f / total_possible * 100).round(2)
  end

  def get_most_used_in(question)
    usage_counts = {}
    usage_counts["Quizzes"] = question.quiz_questions.count
    usage_counts["Assessments"] = question.assessment_questions.count

    usage_counts.max_by { |k, v| v }.first
  end

  def get_usage_by_difficulty(question)
    {
      question.question_type => {
        count: 1,
        difficulty: question.difficulty_level
      }
    }
  end

  private

  def build_question_with_defaults(params)
    LmsQuestion.new(
      name: params[:name],
      question: params[:question],
      question_type: params[:question_type],
      marks: params[:marks] || 10,
      difficulty_level: params[:difficulty_level] || "Medium",
      category: params[:category] || "General",
      owner: params[:owner],
      option_1: params[:option_1],
      option_2: params[:option_2],
      option_3: params[:option_3],
      option_4: params[:option_4],
      option_5: params[:option_5],
      correct_answer: params[:correct_answer],
      explanation: params[:explanation],
      tags: params[:tags] || [],
      is_public: params[:is_public] || true,
      status: params[:status] || "Active"
    )
  end
end
