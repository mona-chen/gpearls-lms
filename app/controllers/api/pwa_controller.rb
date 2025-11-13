class Api::PwaController < Api::BaseController
  # GET /api/pwa-manifest
  def manifest
    settings = LmsSetting.current_settings
    branding = get_branding_settings
    
    manifest_data = {
      name: settings[:app_name] || "LMS Platform",
      short_name: settings[:app_short_name] || "LMS",
      description: settings[:app_description] || "Learning Management System",
      start_url: "/",
      display: "standalone",
      theme_color: branding[:primary_color] || "#2196F3",
      background_color: branding[:background_color] || "#ffffff",
      orientation: "portrait-primary",
      scope: "/",
      lang: "en",
      categories: ["education", "productivity"],
      
      icons: generate_app_icons(branding),
      
      shortcuts: [
        {
          name: "My Courses",
          short_name: "Courses",
          description: "View your enrolled courses",
          url: "/courses",
          icons: [{ src: "/icons/courses-96x96.png", sizes: "96x96" }]
        },
        {
          name: "My Progress",
          short_name: "Progress",
          description: "Check your learning progress",
          url: "/progress",
          icons: [{ src: "/icons/progress-96x96.png", sizes: "96x96" }]
        },
        {
          name: "Notifications",
          short_name: "Notifications",
          description: "View your notifications",
          url: "/notifications",
          icons: [{ src: "/icons/notifications-96x96.png", sizes: "96x96" }]
        }
      ],
      
      screenshots: generate_app_screenshots,
      
      related_applications: [],
      prefer_related_applications: false,
      
      # PWA features
      features: [
        "offline-support",
        "background-sync",
        "push-notifications"
      ],
      
      # Custom LMS-specific metadata
      lms_config: {
        offline_lessons: settings[:offline_lessons_enabled] || false,
        offline_quizzes: settings[:offline_quizzes_enabled] || false,
        background_sync: settings[:background_sync_enabled] || true,
        push_notifications: settings[:push_notifications_enabled] || true
      }
    }
    
    respond_to do |format|
      format.json { render json: manifest_data }
      format.any { render json: manifest_data, content_type: 'application/manifest+json' }
    end
  end
  
  # GET /api/pwa/service-worker
  def service_worker
    service_worker_content = generate_service_worker_content
    
    render plain: service_worker_content, content_type: 'application/javascript'
  end
  
  # POST /api/pwa/install-prompt
  def track_install_prompt
    user_agent = request.user_agent
    platform = detect_platform(user_agent)
    
    # Track PWA install prompt analytics
    PwaInstallTracking.create!(
      user: current_user,
      action: params[:action], # 'prompted', 'accepted', 'dismissed'
      platform: platform,
      user_agent: user_agent,
      timestamp: Time.current
    )
    
    render json: { success: true, message: "Install prompt tracked" }
  end
  
  # GET /api/pwa/offline-content
  def offline_content
    return render json: { error: "Authentication required" }, status: :unauthorized unless current_user
    
    # Get user's enrolled courses and their downloadable content
    enrolled_courses = current_user.courses.includes(:course_lessons, :quizzes)
    
    offline_content = {
      courses: [],
      lessons: [],
      quizzes: [],
      resources: [],
      last_sync: Time.current
    }
    
    enrolled_courses.each do |course|
      # Course basic info
      offline_content[:courses] << {
        id: course.id,
        title: course.title,
        description: course.description,
        image: course.image.attached? ? url_for(course.image) : nil,
        updated_at: course.updated_at
      }
      
      # Course lessons
      course.course_lessons.each do |lesson|
        lesson_data = {
          id: lesson.id,
          course_id: course.id,
          title: lesson.title,
          body: sanitize_content_for_offline(lesson.body),
          lesson_type: lesson.lesson_type,
          updated_at: lesson.updated_at
        }
        
        # Add downloadable resources
        if lesson.attachments.any?
          lesson_data[:attachments] = lesson.attachments.map do |attachment|
            {
              filename: attachment.filename.to_s,
              url: url_for(attachment),
              size: attachment.byte_size,
              content_type: attachment.content_type
            }
          end
        end
        
        offline_content[:lessons] << lesson_data
      end
      
      # Course quizzes (if offline quizzes enabled)
      if offline_quizzes_enabled?
        course.quizzes.each do |quiz|
          quiz_data = {
            id: quiz.id,
            course_id: course.id,
            title: quiz.title,
            description: quiz.description,
            questions: quiz.lms_questions.map do |question|
              {
                id: question.id,
                question: question.question,
                type: question.question_type,
                options: question.options,
                # Don't include correct answers for security
                max_points: question.marks
              }
            end,
            updated_at: quiz.updated_at
          }
          
          offline_content[:quizzes] << quiz_data
        end
      end
    end
    
    render json: offline_content
  end
  
  # POST /api/pwa/sync-offline-data
  def sync_offline_data
    return render json: { error: "Authentication required" }, status: :unauthorized unless current_user
    
    sync_data = params[:sync_data] || {}
    results = {
      lesson_progress: [],
      video_progress: [],
      quiz_submissions: [],
      errors: []
    }
    
    begin
      # Sync lesson progress
      if sync_data[:lesson_progress]
        sync_data[:lesson_progress].each do |progress_data|
          result = sync_lesson_progress_data(progress_data)
          results[:lesson_progress] << result
        end
      end
      
      # Sync video watch duration
      if sync_data[:video_progress]
        sync_data[:video_progress].each do |video_data|
          result = sync_video_progress_data(video_data)
          results[:video_progress] << result
        end
      end
      
      # Sync quiz submissions (if allowed)
      if sync_data[:quiz_submissions] && offline_quiz_submission_enabled?
        sync_data[:quiz_submissions].each do |quiz_data|
          result = sync_quiz_submission_data(quiz_data)
          results[:quiz_submissions] << result
        end
      end
      
      render json: {
        success: true,
        message: "Offline data synced successfully",
        results: results,
        synced_at: Time.current
      }
      
    rescue => e
      Rails.logger.error "Offline sync error: #{e.message}"
      render json: { 
        error: "Sync failed", 
        message: e.message,
        partial_results: results 
      }, status: :internal_server_error
    end
  end
  
  # GET /api/pwa/cache-status
  def cache_status
    # Get cache information for the current user
    cache_info = {
      courses_cached: get_cached_courses_count,
      lessons_cached: get_cached_lessons_count,
      resources_cached: get_cached_resources_count,
      cache_size: calculate_cache_size,
      last_cache_update: get_last_cache_update,
      cache_version: Rails.application.config.cache_version_id || "1.0"
    }
    
    render json: cache_info
  end
  
  private
  
  def get_branding_settings
    # Get branding settings from LMS settings or database
    settings = LmsSetting.current_settings
    {
      primary_color: settings[:primary_color] || "#2196F3",
      background_color: settings[:background_color] || "#ffffff",
      app_icon: settings[:app_icon_url],
      logo_url: settings[:logo_url]
    }
  end
  
  def generate_app_icons(branding)
    base_icon_url = branding[:app_icon] || "/icons/default-icon"
    
    icon_sizes = [72, 96, 128, 144, 152, 192, 384, 512]
    
    icon_sizes.map do |size|
      {
        src: "#{base_icon_url}-#{size}x#{size}.png",
        sizes: "#{size}x#{size}",
        type: "image/png",
        purpose: size >= 192 ? "any maskable" : "any"
      }
    end
  end
  
  def generate_app_screenshots
    [
      {
        src: "/screenshots/courses-view.png",
        sizes: "1280x720",
        type: "image/png",
        form_factor: "wide",
        label: "Courses Overview"
      },
      {
        src: "/screenshots/lesson-view.png", 
        sizes: "750x1334",
        type: "image/png",
        form_factor: "narrow",
        label: "Lesson Learning"
      },
      {
        src: "/screenshots/quiz-view.png",
        sizes: "750x1334", 
        type: "image/png",
        form_factor: "narrow",
        label: "Interactive Quizzes"
      }
    ]
  end
  
  def generate_service_worker_content
    <<~JAVASCRIPT
      const CACHE_NAME = 'lms-pwa-v#{Rails.application.config.cache_version_id || "1"}';
      const urlsToCache = [
        '/',
        '/courses',
        '/offline.html',
        '/css/app.css',
        '/js/app.js',
        '/icons/icon-192x192.png'
      ];
      
      // Install event
      self.addEventListener('install', function(event) {
        event.waitUntil(
          caches.open(CACHE_NAME)
            .then(function(cache) {
              return cache.addAll(urlsToCache);
            })
        );
      });
      
      // Fetch event
      self.addEventListener('fetch', function(event) {
        event.respondWith(
          caches.match(event.request)
            .then(function(response) {
              // Return cached version or fetch from network
              return response || fetch(event.request);
            })
        );
      });
      
      // Background sync for offline data
      self.addEventListener('sync', function(event) {
        if (event.tag === 'offline-data-sync') {
          event.waitUntil(syncOfflineData());
        }
      });
      
      // Push notification handling
      self.addEventListener('push', function(event) {
        const options = {
          body: event.data ? event.data.text() : 'New notification',
          icon: '/icons/icon-192x192.png',
          badge: '/icons/badge-72x72.png'
        };
        
        event.waitUntil(
          self.registration.showNotification('LMS Platform', options)
        );
      });
      
      function syncOfflineData() {
        return fetch('/api/pwa/sync-offline-data', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            sync_data: getStoredOfflineData()
          })
        });
      }
      
      function getStoredOfflineData() {
        // Retrieve offline data from IndexedDB or localStorage
        // This would be implemented based on the client-side storage strategy
        return {};
      }
    JAVASCRIPT
  end
  
  def detect_platform(user_agent)
    case user_agent
    when /iPhone|iPad/
      'ios'
    when /Android/
      'android'
    when /Windows/
      'windows'
    when /Macintosh/
      'macos'
    else
      'unknown'
    end
  end
  
  def sanitize_content_for_offline(content)
    # Remove or modify content that won't work offline
    # This is a basic implementation - you might want to use a proper HTML sanitizer
    content&.gsub(/src="https?:\/\/[^"]*"/, 'src=""')
           &.gsub(/href="https?:\/\/[^"]*"/, 'href="#"')
  end
  
  def offline_quizzes_enabled?
    LmsSetting.current_settings[:offline_quizzes_enabled] || false
  end
  
  def offline_quiz_submission_enabled?
    LmsSetting.current_settings[:offline_quiz_submission_enabled] || false
  end
  
  def sync_lesson_progress_data(progress_data)
    lesson = CourseLesson.find(progress_data[:lesson_id])
    
    progress = LessonProgress.find_or_create_by(
      user: current_user,
      lesson: lesson
    ) do |p|
      p.status = progress_data[:status]
      p.progress = progress_data[:progress]
    end
    
    if progress.updated_at < Time.parse(progress_data[:timestamp])
      progress.update!(
        status: progress_data[:status],
        progress: progress_data[:progress]
      )
    end
    
    { lesson_id: lesson.id, status: 'synced', updated: progress.updated_at }
  rescue => e
    { lesson_id: progress_data[:lesson_id], status: 'error', error: e.message }
  end
  
  def sync_video_progress_data(video_data)
    lesson = CourseLesson.find(video_data[:lesson_id])
    
    VideoWatchDuration.track_duration(
      current_user,
      lesson,
      video_data[:video_url],
      video_data[:duration_watched],
      video_data[:video_length]
    )
    
    { lesson_id: lesson.id, video_url: video_data[:video_url], status: 'synced' }
  rescue => e
    { lesson_id: video_data[:lesson_id], status: 'error', error: e.message }
  end
  
  def sync_quiz_submission_data(quiz_data)
    # Only allow quiz submission sync if explicitly enabled
    return { quiz_id: quiz_data[:quiz_id], status: 'disabled' } unless offline_quiz_submission_enabled?
    
    quiz = Quiz.find(quiz_data[:quiz_id])
    
    # Create quiz submission from offline data
    submission = quiz.quiz_submissions.create!(
      user: current_user,
      answers: quiz_data[:answers],
      submitted_at: Time.parse(quiz_data[:submitted_at]),
      offline_submission: true
    )
    
    { quiz_id: quiz.id, submission_id: submission.id, status: 'synced' }
  rescue => e
    { quiz_id: quiz_data[:quiz_id], status: 'error', error: e.message }
  end
  
  def get_cached_courses_count
    current_user&.courses&.count || 0
  end
  
  def get_cached_lessons_count
    return 0 unless current_user
    
    CourseLesson.joins(course: :enrollments)
                .where(enrollments: { user: current_user })
                .count
  end
  
  def get_cached_resources_count
    # This would depend on your resource tracking implementation
    0
  end
  
  def calculate_cache_size
    # This would require implementing cache size calculation
    # based on your caching strategy
    "0 MB"
  end
  
  def get_last_cache_update
    # Return the last time cache was updated
    Time.current - 1.day # Placeholder
  end
end