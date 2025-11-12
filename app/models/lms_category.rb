class LmsCategory < ApplicationRecord
  # Associations
  has_many :courses, dependent: :restrict_with_error
  has_many :programs, class_name: 'LmsProgram', dependent: :restrict_with_error
  has_many :batches, class_name: 'Batch', dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :parent_category, inclusion: { in: %w[Technology Business Design Personal Development Health Science Arts Language Marketing Sales Management Finance], allow_blank: true }
  validates :icon, presence: true
  validates :color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :is_active, inclusion: { in: [true, false] }

  # Callbacks
  before_validation :set_defaults
  before_save :update_position

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_position, -> { order(position: :asc) }
  scope :by_parent, ->(parent) { where(parent_category: parent) }
  scope :technology, -> { where(parent_category: 'Technology') }
  scope :business, -> { where(parent_category: 'Business') }
  scope :design, -> { where(parent_category: 'Design') }
  scope :personal_development, -> { where(parent_category: 'Personal Development') }
  scope :health_science, -> { where(parent_category: 'Health Science') }
  scope :arts, -> { where(parent_category: 'Arts') }
  scope :language, -> { where(parent_category: 'Language') }
  scope :marketing, -> { where(parent_category: 'Marketing') }
  scope :sales, -> { where(parent_category: 'Sales') }
  scope :management, -> { where(parent_category: 'Management') }
  scope :finance, -> { where(parent_category: 'Finance') }

  # Class methods
  def self.active_categories
    active.by_position
  end

  def self.categories_by_type(type)
    case type.downcase
    when 'technology'
      technology
    when 'business'
      business
    when 'design'
      design
    when 'personal development'
      personal_development
    when 'health science'
      health_science
    when 'arts'
      arts
    when 'language'
      language
    when 'marketing'
      marketing
    when 'sales'
      sales
    when 'management'
      management
    when 'finance'
      finance
    else
      active
    end
  end

  def self.get_categories_for_select
    active.by_position.map { |cat| [cat.name, cat.name] }
  end

  def self.get_parent_categories
    distinct.where.not(parent_category: [nil, ''])
        .pluck(:parent_category)
        .map { |cat| [cat, cat] }
        .sort
  end

  # Instance methods
  def active?
    is_active
  end

  def parent_category_name
    parent_category&.titleize
  end

  def course_count
    courses.count
  end

  def total_enrollments
    courses.joins(:enrollments).count
  end

  def average_course_rating
    # This would be calculated from course reviews
    # Implementation pending CourseReview model
    0.0
  end

  def to_frappe_format
    {
      name: name,
      description: description,
      parent_category: parent_category,
      icon: icon,
      color: color,
      position: position,
      is_active: is_active,
      course_count: course_count,
      total_enrollments: total_enrollments,
      average_rating: average_rating,
      creation: created_at&.strftime('%Y-%m-%d %H:%M:%S'),
      modified: updated_at&.strftime('%Y-%m-%d %H:%M:%S')
    }
  end

  private

  def set_defaults
    self.is_active ||= true
    self.position ||= LmsCategory.maximum(:position).to_i + 1
  end

  def update_position
    # Auto-adjust position if manually set to 0
    self.position = LmsCategory.maximum(:position).to_i + 1 if position.blank? || position == 0
  end

  def self.default_categories
    [
      {
        name: 'Web Development',
        description: 'Learn modern web development technologies including frontend and backend frameworks',
        parent_category: 'Technology',
        icon: 'laptop-code',
        color: '#3B82F6',
        position: 1
      },
      {
        name: 'Mobile Development',
        description: 'Master mobile app development for iOS and Android platforms',
        parent_category: 'Technology',
        icon: 'smartphone',
        color: '#10B981',
        position: 2
      },
      {
        name: 'Data Science',
        description: 'Explore data analysis, machine learning, and artificial intelligence',
        parent_category: 'Technology',
        icon: 'database',
        color: '#8B5CF6',
        position: 3
      },
      {
        name: 'Cloud Computing',
        description: 'Learn cloud architecture, deployment, and management',
        parent_category: 'Technology',
        icon: 'cloud',
        color: '#06B6D4',
        position: 4
      },
      {
        name: 'Digital Marketing',
        description: 'Master online marketing strategies including SEO, SEM, and social media',
        parent_category: 'Marketing',
        icon: 'trending-up',
        color: '#F59E0B',
        position: 10
      },
      {
        name: 'Business Strategy',
        description: 'Develop strategic thinking and business planning skills',
        parent_category: 'Business',
        icon: 'briefcase',
        color: '#1F2937',
        position: 11
      },
      {
        name: 'Project Management',
        description: 'Learn agile methodologies and project management best practices',
        parent_category: 'Management',
        icon: 'users',
        color: '#6B7280',
        position: 20
      },
      {
        name: 'Financial Analysis',
        description: 'Master financial modeling, investment analysis, and financial planning',
        parent_category: 'Finance',
        icon: 'chart-line',
        color: '#059669',
        position: 30
      },
      {
        name: 'Personal Growth',
        description: 'Develop personal effectiveness and soft skills for career advancement',
        parent_category: 'Personal Development',
        icon: 'user',
        color: '#8B5CF6',
        position: 40
      },
      {
        name: 'Health & Wellness',
        description: 'Explore physical and mental health topics for better well-being',
        parent_category: 'Health Science',
        icon: 'heart',
        color: '#EF4444',
        position: 50
      },
      {
        name: 'Creative Arts',
        description: 'Express yourself through various forms of artistic creation',
        parent_category: 'Arts',
        icon: 'palette',
        color: '#EC4899',
        position: 60
      },
      {
        name: 'Language Learning',
        description: 'Master new languages for communication and cultural understanding',
        parent_category: 'Language',
        icon: 'globe',
        color: '#3B82F6',
        position: 70
      }
    ]
  end
end
