# frozen_string_literal: true

class LmsQuiz < ApplicationRecord
  # Associations
  belongs_to :course, class_name: "Course", optional: false
  belongs_to :creator, class_name: "User", foreign_key: true, optional: false
  
  has_many :quiz_questions, dependent: :destroy
  has_many :quiz_results, dependent: :destroy
  has_many :quiz_submissions, through: :quiz_results
  
  # Validations
  validates :name, presence: true, uniqueness: { scope: :course }
  validates :title, presence: true
  validates :description, presence: true
  validates :course, presence: true
  validates :creator, presence: true
  validates :max_attempts, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :passing_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :status, presence: true, inclusion: { in: %w[Draft Published Ended] }
  
  # Scopes
  scope :draft, -> { where(status: "Draft") }
  scope :published, -> { where(status: "Published") }
  scope :ended, -> { where(status: "Ended") }
  scope :by_course, ->(course) { where(course: course) }
  scope :by_creator, ->(creator) { where(creator: creator) }
  scope :active, -> { where(status: "Published").where("start_date <= ? AND (end_date >= ? OR end_date IS NULL)", Time.current, Time.current) }
  
  # Callbacks
  before_validation :set_default_values
  
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
  
  def can_start?(user)
    return false unless active?
    return false unless has_remaining_attempts?(user)
    return false unless user.enrolled_in?(course)
    true
  end
  
  def has_remaining_attempts?(user)
    used_attempts = quiz_results.where(user: user).count
    used_attempts < max_attempts
  end
  
  def to_frappe_format
    {
      name: name,
      title: title,
      description: description,
      course: course&.name,
      batch: batch&.name,
      creator: creator&.email,
      max_attempts: max_attempts,
      duration_minutes: duration_minutes,
      passing_percentage: passing_percentage,
      status: status,
      total_attempts: quiz_results.count,
      unique_users: quiz_results.count("user_id"),
      average_score: quiz_results.average(:score)&.round(2) || 0,
      highest_score: quiz_results.maximum(:score) || 0,
      lowest_score: quiz_results.minimum(:score) || 0,
      pass_rate: calculate_pass_rate,
      questions_count: quiz_questions.count,
      active: active?,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end
  
  # Class Methods
  def self.create_quiz(params)
    quiz = build_quiz_with_defaults(params)
    
    if quiz.save
      {
        success: true,
        quiz: quiz,
        message: "Quiz created successfully"
      }
    else
      {
        success: false,
        error: "Failed to create quiz",
        details: quiz.errors.full_messages
      }
    end
  end
  
  def self.get_course_quizzes(course, options = {})
    quizzes = course.quizzes.includes(:creator, :batch, :quiz_questions)
    
    # Apply filters
    quizzes = quizzes.where(status: options[:status]) if options[:status].present?
    quizzes = quizzes.where(creator: options[:creator]) if options[:creator].present?
    quizzes = quizzes.where(batch: options[:batch]) if options[:batch].present?
    
    # Apply pagination
    limit = options[:limit] || 20
    offset = options[:offset] || 0
    quizzes = quizzes.limit(limit).offset(offset)
    
    quizzes.map(&:to_frappe_format)
  end
  
  private
  
  def set_default_values
    self.status ||= "Draft"
    self.max_attempts ||= 1
    self.duration_minutes ||= 60
    self.passing_percentage ||= 70.0
  end
  
  def calculate_pass_rate
    return 0 if quiz_results.empty?
    
    passing_marks = (max_marks.to_f * passing_percentage / 100).round(2)
    passed_count = quiz_results.select { |result| result.score >= passing_marks }.count
    
    (passed_count.to_f / quiz_results.count * 100).round(2)
  end
  
  def build_quiz_with_defaults(params)
    LmsQuiz.new(
      name: params[:name],
      title: params[:title],
      description: params[:description],
      course: params[:course],
      batch: params[:batch],
      creator: params[:creator],
      max_attempts: params[:max_attempts] || 1,
      duration_minutes: params[:duration_minutes] || 60,
      passing_percentage: params[:passing_percentage] || 70.0,
      status: params[:status] || "Draft"
    )
  end
end
