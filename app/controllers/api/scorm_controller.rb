class Api::ScormController < Api::BaseController
  before_action :authenticate_user!
  before_action :find_scorm_package, only: [:launch, :track, :get_value, :set_value, :commit]
  
  # POST /api/scorm/upload
  def upload
    lesson_id = params[:lesson_id]
    file = params[:file]
    
    return render json: { error: "Lesson ID and file are required" }, status: :bad_request unless lesson_id && file
    
    begin
      lesson = CourseLesson.find(lesson_id)
      
      # Check if user has permission to upload SCORM to this lesson
      unless can_upload_scorm?(lesson, current_user)
        return render json: { error: "Unauthorized" }, status: :unauthorized
      end
      
      # Validate file type
      unless valid_scorm_file?(file)
        return render json: { error: "Invalid SCORM package file" }, status: :bad_request
      end
      
      scorm_package = ScormPackage.create_from_upload(lesson, file, current_user)
      
      render json: {
        success: true,
        package_id: scorm_package.id,
        message: "SCORM package uploaded successfully. Processing...",
        status: scorm_package.status
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Lesson not found" }, status: :not_found
    rescue => e
      Rails.logger.error "SCORM upload error: #{e.message}"
      render json: { error: "Failed to upload SCORM package" }, status: :internal_server_error
    end
  end
  
  # GET /api/scorm/:id/launch
  def launch
    return render json: { error: "Package not ready" }, status: :unprocessable_entity unless @package.extracted?
    
    # Initialize or get existing completion record
    completion = ScormCompletion.find_or_create_by(
      user: current_user,
      scorm_package: @package,
      course_lesson: @package.course_lesson
    ) do |c|
      c.completion_status = :not_attempted
      c.started_at = Time.current
    end
    
    render json: {
      launch_url: @package.launch_url,
      completion_id: completion.id,
      suspend_data: completion.suspend_data,
      location: completion.location,
      score: completion.score_raw,
      completion_status: completion.completion_status,
      session_token: generate_session_token(completion)
    }
  end
  
  # POST /api/scorm/:id/track
  def track
    scorm_data = params[:scorm_data] || {}
    
    begin
      completion = ScormCompletion.track_scorm_interaction(
        current_user,
        @package,
        @package.course_lesson,
        scorm_data
      )
      
      render json: {
        success: true,
        completion_status: completion.completion_status,
        progress_percentage: completion.progress_percentage,
        message: "SCORM data tracked successfully"
      }
    rescue => e
      Rails.logger.error "SCORM tracking error: #{e.message}"
      render json: { error: "Failed to track SCORM data" }, status: :internal_server_error
    end
  end
  
  # GET /api/scorm/:id/get-value
  def get_value
    element = params[:element]
    
    completion = ScormCompletion.find_by(
      user: current_user,
      scorm_package: @package
    )
    
    value = get_scorm_value(completion, element)
    
    render json: { element: element, value: value }
  end
  
  # POST /api/scorm/:id/set-value
  def set_value
    element = params[:element]
    value = params[:value]
    
    completion = ScormCompletion.find_or_create_by(
      user: current_user,
      scorm_package: @package,
      course_lesson: @package.course_lesson
    )
    
    success = set_scorm_value(completion, element, value)
    
    render json: { success: success, element: element, value: value }
  end
  
  # POST /api/scorm/:id/commit
  def commit
    completion = ScormCompletion.find_by(
      user: current_user,
      scorm_package: @package
    )
    
    if completion
      completion.update!(last_accessed_at: Time.current)
      render json: { success: true, message: "Data committed successfully" }
    else
      render json: { success: false, error: "No completion record found" }
    end
  end
  
  # GET /api/scorm/:id/analytics
  def analytics
    unless can_view_scorm_analytics?(@package, current_user)
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end
    
    analytics = ScormCompletion.get_analytics_for_package(@package)
    completions = @package.scorm_completions.includes(:user).order(:last_accessed_at)
    
    render json: {
      package_id: @package.id,
      package_title: @package.title,
      analytics: analytics,
      recent_activity: completions.limit(20).map do |c|
        {
          user_email: c.user.email,
          completion_status: c.completion_status,
          score: c.score_raw,
          progress: c.progress_percentage,
          last_accessed: c.last_accessed_at,
          total_time: c.total_time
        }
      end
    }
  end
  
  # GET /api/scorm/packages/:lesson_id
  def packages_for_lesson
    lesson = CourseLesson.find(params[:lesson_id])
    packages = lesson.scorm_packages.order(:created_at)
    
    render json: {
      lesson_id: lesson.id,
      packages: packages.map do |package|
        {
          id: package.id,
          title: package.title,
          status: package.status,
          version: package.version,
          launch_url: package.launch_url,
          uploaded_at: package.created_at,
          extracted_at: package.extracted_at,
          metadata: package.metadata
        }
      end
    }
  end
  
  # DELETE /api/scorm/:id
  def destroy
    unless can_delete_scorm?(@package, current_user)
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end
    
    begin
      # Clean up files
      FileUtils.rm_rf(@package.extracted_path) if @package.extracted_path&.present?
      
      # Delete package record (will cascade to completions)
      @package.destroy!
      
      render json: { success: true, message: "SCORM package deleted successfully" }
    rescue => e
      Rails.logger.error "SCORM deletion error: #{e.message}"
      render json: { error: "Failed to delete SCORM package" }, status: :internal_server_error
    end
  end
  
  private
  
  def find_scorm_package
    @package = ScormPackage.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "SCORM package not found" }, status: :not_found
  end
  
  def can_upload_scorm?(lesson, user)
    return true if user.admin?
    lesson.course.instructors.include?(user) || user.has_role?(:content_creator)
  end
  
  def can_view_scorm_analytics?(package, user)
    return true if user.admin?
    package.course_lesson.course.instructors.include?(user) || user.has_role?(:analytics_viewer)
  end
  
  def can_delete_scorm?(package, user)
    return true if user.admin?
    package.uploaded_by == user || package.course_lesson.course.instructors.include?(user)
  end
  
  def valid_scorm_file?(file)
    # Check file extension and content type
    allowed_types = ['application/zip', 'application/x-zip-compressed']
    allowed_extensions = ['.zip']
    
    file_extension = File.extname(file.original_filename).downcase
    content_type = file.content_type
    
    allowed_extensions.include?(file_extension) && allowed_types.include?(content_type)
  end
  
  def generate_session_token(completion)
    # Generate a secure token for this SCORM session
    payload = {
      completion_id: completion.id,
      user_id: current_user.id,
      package_id: completion.scorm_package_id,
      timestamp: Time.current.to_i
    }
    
    JWT.encode(payload, Rails.application.secret_key_base)
  end
  
  def get_scorm_value(completion, element)
    return '' unless completion
    
    case element
    when 'cmi.core.lesson_status'
      map_completion_status_to_scorm(completion.completion_status)
    when 'cmi.core.score.raw'
      completion.score_raw.to_s
    when 'cmi.core.score.min'
      completion.score_min.to_s
    when 'cmi.core.score.max'
      completion.score_max.to_s
    when 'cmi.core.total_time'
      format_time_for_scorm(completion.total_time)
    when 'cmi.suspend_data'
      completion.suspend_data || ''
    when 'cmi.core.location'
      completion.location || ''
    when 'cmi.core.student_id'
      current_user.id.to_s
    when 'cmi.core.student_name'
      current_user.full_name || current_user.email
    else
      completion.scorm_data&.dig(element) || ''
    end
  end
  
  def set_scorm_value(completion, element, value)
    scorm_data = completion.scorm_data || {}
    scorm_data[element] = value
    
    case element
    when 'cmi.core.lesson_status'
      completion.completion_status = map_scorm_status_to_completion(value)
    when 'cmi.core.score.raw'
      completion.score_raw = value.to_f
    when 'cmi.core.score.min'
      completion.score_min = value.to_f
    when 'cmi.core.score.max'
      completion.score_max = value.to_f
    when 'cmi.core.total_time'
      completion.total_time = parse_scorm_time(value)
    when 'cmi.core.session_time'
      completion.session_time = parse_scorm_time(value)
    when 'cmi.suspend_data'
      completion.suspend_data = value
    when 'cmi.core.location'
      completion.location = value
    end
    
    completion.scorm_data = scorm_data
    completion.last_accessed_at = Time.current
    completion.save!
    
    true
  rescue => e
    Rails.logger.error "SCORM set value error: #{e.message}"
    false
  end
  
  def map_completion_status_to_scorm(status)
    case status
    when 'completed'
      'completed'
    when 'incomplete'
      'incomplete'
    when 'passed'
      'passed'
    when 'failed'
      'failed'
    when 'browsed'
      'browsed'
    else
      'not attempted'
    end
  end
  
  def map_scorm_status_to_completion(scorm_status)
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
  
  def format_time_for_scorm(seconds)
    return '0000:00:00.00' unless seconds
    
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60
    
    sprintf('%04d:%02d:%02d.00', hours, minutes, secs)
  end
  
  def parse_scorm_time(time_string)
    return 0 unless time_string
    
    if time_string.match?(/^\d{4}:\d{2}:\d{2}/)
      parts = time_string.split(':')
      hours = parts[0].to_i
      minutes = parts[1].to_i
      seconds = parts[2].to_f
      
      hours * 3600 + minutes * 60 + seconds.to_i
    else
      time_string.to_i
    end
  end
end