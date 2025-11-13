class ScormCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :scorm_package
  belongs_to :course_lesson
  
  validates :user_id, uniqueness: { scope: :scorm_package_id }
  
  enum completion_status: { 
    incomplete: 0, 
    completed: 1, 
    passed: 2, 
    failed: 3, 
    browsed: 4,
    not_attempted: 5
  }
  
  enum success_status: {
    unknown: 0,
    passed_success: 1,
    failed_success: 2
  }
  
  scope :by_lesson, ->(lesson) { where(course_lesson: lesson) }
  scope :by_package, ->(package) { where(scorm_package: package) }
  scope :completed_users, -> { where(completion_status: [:completed, :passed]) }
  
  def progress_percentage
    return 0 if total_time.nil? || total_time.zero?
    
    # Calculate based on completion status and score
    case completion_status
    when 'completed', 'passed'
      100
    when 'failed'
      50
    when 'browsed'
      25
    when 'incomplete'
      [score_raw.to_f, 0].max
    else
      0
    end
  end
  
  def update_from_scorm_data(scorm_data)
    update_attributes = {}
    
    # Core tracking data
    update_attributes[:completion_status] = map_completion_status(scorm_data['cmi.core.lesson_status'])
    update_attributes[:success_status] = map_success_status(scorm_data['cmi.core.success_status'])
    update_attributes[:score_raw] = scorm_data['cmi.core.score.raw'].to_f if scorm_data['cmi.core.score.raw']
    update_attributes[:score_min] = scorm_data['cmi.core.score.min'].to_f if scorm_data['cmi.core.score.min']
    update_attributes[:score_max] = scorm_data['cmi.core.score.max'].to_f if scorm_data['cmi.core.score.max']
    update_attributes[:total_time] = parse_scorm_time(scorm_data['cmi.core.total_time'])
    update_attributes[:session_time] = parse_scorm_time(scorm_data['cmi.core.session_time'])
    
    # Suspend data for resuming
    update_attributes[:suspend_data] = scorm_data['cmi.suspend_data'] if scorm_data['cmi.suspend_data']
    update_attributes[:location] = scorm_data['cmi.core.location'] if scorm_data['cmi.core.location']
    
    # Student responses and interactions
    interactions = extract_interactions(scorm_data)
    update_attributes[:interactions_data] = interactions if interactions.any?
    
    # Objectives
    objectives = extract_objectives(scorm_data)
    update_attributes[:objectives_data] = objectives if objectives.any?
    
    update_attributes[:last_accessed_at] = Time.current
    update_attributes[:scorm_data] = scorm_data
    
    update!(update_attributes)
    
    # Update lesson progress if completed
    update_lesson_progress if completed_or_passed?
  end
  
  def completed_or_passed?
    completed? || passed?
  end
  
  def self.track_scorm_interaction(user, package, lesson, scorm_data)
    completion = find_or_create_by(
      user: user,
      scorm_package: package,
      course_lesson: lesson
    ) do |c|
      c.completion_status = :not_attempted
      c.success_status = :unknown
      c.started_at = Time.current
    end
    
    completion.update_from_scorm_data(scorm_data)
    completion
  end
  
  def self.get_analytics_for_package(package)
    completions = where(scorm_package: package)
    
    {
      total_attempts: completions.count,
      completed_count: completions.completed_users.count,
      average_score: completions.where.not(score_raw: nil).average(:score_raw) || 0,
      completion_rate: completions.count > 0 ? (completions.completed_users.count.to_f / completions.count * 100) : 0,
      average_time_spent: completions.where.not(total_time: nil).average(:total_time) || 0,
      status_distribution: completions.group(:completion_status).count
    }
  end
  
  private
  
  def map_completion_status(scorm_status)
    case scorm_status&.downcase
    when 'completed'
      :completed
    when 'incomplete'
      :incomplete
    when 'failed'
      :failed
    when 'passed'
      :passed
    when 'browsed'
      :browsed
    else
      :not_attempted
    end
  end
  
  def map_success_status(scorm_success)
    case scorm_success&.downcase
    when 'passed'
      :passed_success
    when 'failed'
      :failed_success
    else
      :unknown
    end
  end
  
  def parse_scorm_time(time_string)
    return nil unless time_string
    
    # Parse SCORM time format (e.g., "PT1H23M45S" or "0000:12:34.56")
    if time_string.match?(/^PT/)
      # ISO 8601 duration format
      match = time_string.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?/)
      hours = match[1].to_i
      minutes = match[2].to_i
      seconds = match[3].to_f
      
      (hours * 3600 + minutes * 60 + seconds).to_i
    elsif time_string.match?(/^\d{4}:\d{2}:\d{2}/)
      # SCORM 1.2 format (HHHH:MM:SS.SS)
      parts = time_string.split(':')
      hours = parts[0].to_i
      minutes = parts[1].to_i
      seconds = parts[2].to_f
      
      (hours * 3600 + minutes * 60 + seconds).to_i
    else
      time_string.to_i
    end
  end
  
  def extract_interactions(scorm_data)
    interactions = []
    
    scorm_data.each do |key, value|
      if key.match?(/^cmi\.interactions\.(\d+)\.(.+)/)
        interaction_index = $1.to_i
        interaction_field = $2
        
        interactions[interaction_index] ||= {}
        interactions[interaction_index][interaction_field] = value
      end
    end
    
    interactions.compact
  end
  
  def extract_objectives(scorm_data)
    objectives = []
    
    scorm_data.each do |key, value|
      if key.match?(/^cmi\.objectives\.(\d+)\.(.+)/)
        objective_index = $1.to_i
        objective_field = $2
        
        objectives[objective_index] ||= {}
        objectives[objective_index][objective_field] = value
      end
    end
    
    objectives.compact
  end
  
  def update_lesson_progress
    progress = LessonProgress.find_or_create_by(
      user: user,
      lesson_id: course_lesson.id
    ) do |p|
      p.status = 'Complete'
      p.progress = 100
    end
    
    unless progress.status == 'Complete'
      progress.update!(status: 'Complete', progress: 100)
    end
  end
end