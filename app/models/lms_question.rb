class LmsQuestion < ApplicationRecord
  self.table_name = "lms_questions"
  self.inheritance_column = nil

  # Aliases for compatibility
  alias_attribute :question_type, :type

  # Temporary storage for quiz association during creation
  attr_accessor :quiz, :marks

  # Associations
  has_many :lms_quiz_questions, dependent: :destroy
  has_many :lms_quizzes, through: :lms_quiz_questions

  # Validations (matching Frappe exactly)
  validates :question, presence: true
  validates :type, presence: true, inclusion: { in: %w[Choices User\ Input Open\ Ended] }

  # Callbacks (matching Frappe)
  before_validation :validate_correct_answers
  before_create :generate_name
  after_create :associate_with_quiz

  # Scopes
  scope :by_type, ->(type) { where(type: type) }
  scope :choices, -> { where(type: "Choices") }
  scope :user_input, -> { where(type: "User Input") }
  scope :open_ended, -> { where(type: "Open Ended") }

  # Instance methods (matching Frappe functionality)
  def choices?
    type == "Choices"
  end

  def user_input?
    type == "User Input"
  end

  def open_ended?
    type == "Open Ended"
  end

  def correct_options
    return [] unless choices?

    correct = []
    correct << option_1 if is_correct_1?
    correct << option_2 if is_correct_2?
    correct << option_3 if is_correct_3?
    correct << option_4 if is_correct_4?
    correct.compact
  end

  def all_options
    return [] unless choices?

    [ option_1, option_2, option_3, option_4 ].compact.reject(&:empty?)
  end

  def explanation_for_option(option)
    return nil unless choices?

    case option
    when option_1
      explanation_1
    when option_2
      explanation_2
    when option_3
      explanation_3
    when option_4
      explanation_4
    end
  end

  def possible_answers
    return [] unless user_input?

    [ possibility_1, possibility_2, possibility_3, possibility_4 ].compact
  end



  def check_answer(answer)
    case type
    when "Choices"
      correct_options.include?(answer)
    when "User Input"
      possible_answers.any? { |possibility| possibility.strip.downcase == answer.strip.downcase }
    when "Open Ended"
      # Open ended questions are manually graded
      false
    else
      false
    end
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "question" => question,
      "type" => type,
      "multiple" => multiple || false,
      "option_1" => option_1,
      "is_correct_1" => is_correct_1 || false,
      "explanation_1" => explanation_1,
      "option_2" => option_2,
      "is_correct_2" => is_correct_2 || false,
      "explanation_2" => explanation_2,
      "option_3" => option_3,
      "is_correct_3" => is_correct_3 || false,
      "explanation_3" => explanation_3,
      "option_4" => option_4,
      "is_correct_4" => is_correct_4 || false,
      "explanation_4" => explanation_4,
      "possibility_1" => possibility_1,
      "possibility_2" => possibility_2,
      "possibility_3" => possibility_3,
      "possibility_4" => possibility_4,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  private

  def validate_correct_answers
    if type == "Choices"
      validate_duplicate_options
      validate_minimum_options
      validate_correct_options
    elsif type == "User Input"
      validate_possible_answer
    end
  end

  def validate_duplicate_options
    options = []

    [ option_1, option_2, option_3, option_4 ].each do |opt|
      options << opt if opt.present?
    end

    if options.uniq.length != options.length
      errors.add(:base, "Duplicate options found for this question.")
    end
  end

  def validate_minimum_options
    if type == "Choices" && (!option_1.present? || !option_2.present?)
      errors.add(:base, "Minimum two options are required for multiple choice questions.")
    end
  end

  def validate_correct_options
    correct_count = [ is_correct_1, is_correct_2, is_correct_3, is_correct_4 ].count(true)

    if correct_count > 1
      self.multiple = true
    end

    if correct_count == 0
      errors.add(:base, "At least one option must be correct for this question.")
    end
  end

  def validate_possible_answer
    possible_answers_list = [ possibility_1, possibility_2, possibility_3, possibility_4 ].compact

    if possible_answers_list.empty?
      errors.add(:base, "Add at least one possible answer for this question: #{question}")
    end
  end

  def generate_name
    return if name.present?

    # Generate name like QTS-2025-00001 (matching Frappe autoname)
    year = Time.current.year
    sequence = self.class.where("created_at >= ?", Time.current.beginning_of_year).count + 1
    self.name = "QTS-#{year}-#{sequence.to_s.rjust(5, '0')}"
  end

  def associate_with_quiz
    return unless quiz.present?

    position = quiz.lms_quiz_questions.maximum(:position).to_i + 1
    marks_value = marks || 10
    LmsQuizQuestion.create!(lms_quiz: quiz, lms_question: self, marks: marks_value, position: position)
  end

  class << self
    def get_questions(options = {})
      questions = all

      # Apply filters
      questions = questions.where(type: options[:type]) if options[:type].present?

      # Apply sorting
      questions = questions.order(created_at: :desc)

      questions
    end
  end
end
