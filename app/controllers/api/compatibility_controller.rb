class Api::CompatibilityController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  before_action :authenticate_user_from_token!, only: [:get_user_info]

  # Frappe-style API compatibility layer

  def handle_method
    method_path = params[:method_path]
    Rails.logger.info "Received method path: #{method_path}"

    # Authenticate for protected methods
    authenticate_user_from_token! if ['lms.api.get_user_info', 'lms.utils.get_my_courses', 'lms.utils.get_my_batches', 'lms.utils.get_streak_info', 'lms.utils.get_upcoming_evals'].include?(method_path)

    case method_path
    when 'lms.api.get_user_info'
      get_user_info
    when 'lms.api.get_all_users'
      get_all_users
    when 'lms.api.get_branding'
      get_branding
    when 'lms.api.get_lms_setting'
      get_lms_setting
    when 'lms.api.get_translations'
      get_translations
    when 'lms.api.get_sidebar_settings'
      get_sidebar_settings
    when 'lms.utils.get_my_live_classes'
      get_my_live_classes
    when 'lms.utils.get_streak_info'
      get_streak_info
    when 'lms.utils.get_my_courses'
      get_my_courses
    when 'lms.utils.get_my_batches'
      get_my_batches
    when 'lms.utils.get_upcoming_evals'
      get_upcoming_evals
    else
      render json: { error: "Unknown method: #{method_path}" }, status: 404
    end
  end

  def get_user_info
    if current_user
      render json: {
        user: {
          name: current_user.full_name,
          email: current_user.email,
          username: current_user.email.split('@').first,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          user_image: current_user.user_image,
          roles: [current_user.user_type&.titleize || "LMS Student"],
          id: current_user.id,
          is_moderator: current_user.user_type == 'Moderator',
          is_evaluator: current_user.user_type == 'Batch Evaluator',
          is_instructor: current_user.user_type == 'Course Creator'
        }
      }
    else
      render json: {
        user: nil,
        message: 'Not authenticated'
      }, status: :unauthorized
    end
  end
  
  def get_all_users
    # Return mock users data
    render json: [
      {
        name: "Guest User",
        email: "guest@example.com",
        username: "guest",
        first_name: "Guest",
        last_name: "User",
        user_image: nil
      }
    ]
  end
  
  def get_branding
    render json: {
      app_name: "LMS",
      app_logo: nil,
      app_logo_url: "/assets/lms-logo.png",
      favicon: nil,
      favicon_url: "/favicon.png",
      html_css: "",
      splash_image: nil,
      splash_image_url: nil,
      onboarding_video: nil,
      footer_logo: nil,
      footer_logo_url: nil,
      footer_text: "© 2025 LMS. All rights reserved.",
      hide_login: false,
      signup_form: false,
      parent_app: nil,
      integration_request_service: nil,
      integration_request_key: nil,
      restrict_user_domain: false,
      allowed_user_domains: "",
      restrict_signup_by_role: false,
      allowed_signup_roles: "",
      disable_signup: false,
      enable_signup_on_frappe_signup_form: false,
      enable_2fa: false,
      allow_password_reset: true,
      enable_google_auth: false,
      enable_facebook_auth: false,
      enable_frappe_auth: false,
      enable_office365_auth: false,
      enable_github_auth: false
    }
  end
  
  def get_lms_setting
    render json: {
      allow_guest_access: true,
      enable_student_portal: true,
      enable_course_creation: true,
      enable_batch_creation: true,
      enable_certification: true,
      enable_discussions: true,
      enable_quizzes: true,
      enable_assignments: true,
      enable_programming_exercises: true,
      enable_live_classes: true,
      enable_analytics: true,
      enable_notifications: true,
      enable_jobs: true,
      enable_reviews: true,
      enable_ratings: true,
      enable_tags: true,
      enable_categories: true,
      enable_search: true,
      enable_bookmarks: true,
      enable_notes: true,
      enable_progress_tracking: true,
      enable_certificates: true,
      enable_badges: true,
      enable_leaderboard: true,
      enable_social_learning: true,
      enable_mobile_app: true,
      enable_pwa: true,
      enable_dark_mode: true,
      enable_multilingual: true,
      default_language: "en",
      supported_languages: ["en"],
      timezone: "UTC",
      date_format: "YYYY-MM-DD",
      time_format: "24h",
      currency: "USD",
      currency_symbol: "$",
      decimal_places: 2,
      thousands_separator: ",",
      decimal_separator: ".",
      country: "US",
      region: ""
    }
  end
  
  def get_translations
    render json: {
      messages: {
        "Login": "Login",
        "Logout": "Logout",
        "Courses": "Courses",
        "Batches": "Batches",
        "Students": "Students",
        "Instructors": "Instructors",
        "Administrators": "Administrators",
        "Settings": "Settings",
        "Profile": "Profile",
        "Dashboard": "Dashboard",
        "Analytics": "Analytics",
        "Reports": "Reports",
        "Certificates": "Certificates",
        "Badges": "Badges",
        "Jobs": "Jobs",
        "Notifications": "Notifications",
        "Messages": "Messages",
        "Help": "Help",
        "Support": "Support",
        "About": "About",
        "Contact": "Contact",
        "Privacy": "Privacy",
        "Terms": "Terms",
        "FAQ": "FAQ",
        "Documentation": "Documentation",
        "Community": "Community",
        "Blog": "Blog",
        "News": "News",
        "Events": "Events",
        "Webinars": "Webinars",
        "Workshops": "Workshops",
        "Tutorials": "Tutorials",
        "Guides": "Guides",
        "Videos": "Videos",
        "Podcasts": "Podcasts",
        "Books": "Books",
        "Resources": "Resources",
        "Tools": "Tools",
        "Services": "Services",
        "Products": "Products",
        "Solutions": "Solutions",
        "Partners": "Partners",
        "Customers": "Customers",
        "Testimonials": "Testimonials",
        "Case Studies": "Case Studies",
        "Success Stories": "Success Stories",
        "Press": "Press",
        "Media": "Media",
        "Investors": "Investors",
        "Careers": "Careers",
        "Team": "Team",
        "Leadership": "Leadership",
        "Advisors": "Advisors",
        "Board": "Board",
        "Investors": "Investors",
        "Funding": "Funding",
        "Partners": "Partners",
        "Suppliers": "Suppliers",
        "Distributors": "Distributors",
        "Resellers": "Resellers",
        "Affiliates": "Affiliates",
        "Referrals": "Referrals",
        "Partners": "Partners",
        "Members": "Members",
        "Subscribers": "Subscribers",
        "Followers": "Followers",
        "Fans": "Fans",
        "Supporters": "Supporters",
        "Donors": "Donors",
        "Volunteers": "Volunteers",
        "Contributors": "Contributors",
        "Sponsors": "Sponsors",
        "Patrons": "Patrons",
        "Ambassadors": "Ambassadors",
        "Champions": "Champions",
        "Advocates": "Advocates",
        "Evangelists": "Evangelists",
        "Influencers": "Influencers",
        "Experts": "Experts",
        "Thought Leaders": "Thought Leaders",
        "Industry Leaders": "Industry Leaders",
        "Opinion Leaders": "Opinion Leaders",
        "Key Opinion Leaders": "Key Opinion Leaders",
        "Subject Matter Experts": "Subject Matter Experts",
        "Domain Experts": "Domain Experts",
        "Technical Experts": "Technical Experts",
        "Business Experts": "Business Experts",
        "Industry Experts": "Industry Experts",
        "Academic Experts": "Academic Experts",
        "Research Experts": "Research Experts",
        "Clinical Experts": "Clinical Experts",
        "Medical Experts": "Medical Experts",
        "Legal Experts": "Legal Experts",
        "Financial Experts": "Financial Experts",
        "Marketing Experts": "Marketing Experts",
        "Sales Experts": "Sales Experts",
        "HR Experts": "HR Experts",
        "IT Experts": "IT Experts",
        "Operations Experts": "Operations Experts",
        "Supply Chain Experts": "Supply Chain Experts",
        "Logistics Experts": "Logistics Experts",
        "Manufacturing Experts": "Manufacturing Experts",
        "Quality Experts": "Quality Experts",
        "Safety Experts": "Safety Experts",
        "Environmental Experts": "Environmental Experts",
        "Sustainability Experts": "Sustainability Experts",
        "CSR Experts": "CSR Experts",
        "Ethics Experts": "Ethics Experts",
        "Compliance Experts": "Compliance Experts",
        "Risk Experts": "Risk Experts",
        "Security Experts": "Security Experts",
        "Cybersecurity Experts": "Cybersecurity Experts",
        "Data Experts": "Data Experts",
        "AI Experts": "AI Experts",
        "ML Experts": "ML Experts",
        "Blockchain Experts": "Blockchain Experts",
        "IoT Experts": "IoT Experts",
        "Cloud Experts": "Cloud Experts",
        "DevOps Experts": "DevOps Experts",
        "Agile Experts": "Agile Experts",
        "Scrum Experts": "Scrum Experts",
        "Kanban Experts": "Kanban Experts",
        "Lean Experts": "Lean Experts",
        "Six Sigma Experts": "Six Sigma Experts",
        "TQM Experts": "TQM Experts",
        "ISO Experts": "ISO Experts",
        "Audit Experts": "Audit Experts",
        "Tax Experts": "Tax Experts",
        "Accounting Experts": "Accounting Experts",
        "Bookkeeping Experts": "Bookkeeping Experts",
        "Payroll Experts": "Payroll Experts",
        "Benefits Experts": "Benefits Experts",
        "Compensation Experts": "Compensation Experts",
        "Performance Experts": "Performance Experts",
        "Training Experts": "Training Experts",
        "Development Experts": "Development Experts",
        "Coaching Experts": "Coaching Experts",
        "Mentoring Experts": "Mentoring Experts",
        "Career Experts": "Career Experts",
        "Job Experts": "Job Experts",
        "Recruitment Experts": "Recruitment Experts",
        "Talent Experts": "Talent Experts",
        "HRIS Experts": "HRIS Experts",
        "ATS Experts": "ATS Experts",
        "LMS Experts": "LMS Experts",
        "LXP Experts": "LXP Experts",
        "TMS Experts": "TMS Experts",
        "CRM Experts": "CRM Experts",
        "ERP Experts": "ERP Experts",
        "SCM Experts": "SCM Experts",
        "WMS Experts": "WMS Experts",
        "MES Experts": "MES Experts",
        "PLM Experts": "PLM Experts",
        "CAD Experts": "CAD Experts",
        "CAM Experts": "CAM Experts",
        "CAE Experts": "CAE Experts",
        "EDA Experts": "EDA Experts",
        "PCB Experts": "PCB Experts",
        "FPGA Experts": "FPGA Experts",
        "ASIC Experts": "ASIC Experts",
        "SoC Experts": "SoC Experts",
        "Embedded Experts": "Embedded Experts",
        "RTOS Experts": "RTOS Experts",
        "Firmware Experts": "Firmware Experts",
        "Hardware Experts": "Hardware Experts",
        "Semiconductor Experts": "Semiconductor Experts",
        "Photonics Experts": "Photonics Experts",
        "Optics Experts": "Optics Experts",
        "Laser Experts": "Laser Experts",
        "Quantum Experts": "Quantum Experts",
        "Nanotech Experts": "Nanotech Experts",
        "Biotech Experts": "Biotech Experts",
        "Medtech Experts": "Medtech Experts",
        "Healthtech Experts": "Healthtech Experts",
        "Edtech Experts": "Edtech Experts",
        "Fintech Experts": "Fintech Experts",
        "Insurtech Experts": "Insurtech Experts",
        "Regtech Experts": "Regtech Experts",
        "Suptech Experts": "Suptech Experts",
        "Proptech Experts": "Proptech Experts",
        "Contech Experts": "Contech Experts",
        "Govtech Experts": "Govtech Experts",
        "Legaltech Experts": "Legaltech Experts",
        "Foodtech Experts": "Foodtech Experts",
        "Agritech Experts": "Agritech Experts",
        "Cleantech Experts": "Cleantech Experts",
        "Climatech Experts": "Climatech Experts",
        "Energytech Experts": "Energytech Experts",
        "Greentech Experts": "Greentech Experts",
        "Sustainabilitytech Experts": "Sustainabilitytech Experts",
        "ESGtech Experts": "ESGtech Experts",
        "Impacttech Experts": "Impacttech Experts",
        "Socialtech Experts": "Socialtech Experts",
        "Humantech Experts": "Humantech Experts",
        "Animaltech Experts": "Animaltech Experts",
        "Pettech Experts": "Pettech Experts",
        "Vettech Experts": "Vettech Experts",
        "Aquatech Experts": "Aquatech Experts",
        "Marinetech Experts": "Marinetech Experts",
        "Spacetech Experts": "Spacetech Experts",
        "Aviationtech Experts": "Aviationtech Experts",
        "Aerotech Experts": "Aerotech Experts",
        "Autotech Experts": "Autotech Experts",
        "Motortech Experts": "Motortech Experts",
        "Biketech Experts": "Biketech Experts",
        "Cycletech Experts": "Cycletech Experts",
        "Mobilitytech Experts": "Mobilitytech Experts",
        "Transporttech Experts": "Transporttech Experts",
        "Railtech Experts": "Railtech Experts",
        "Shippingtech Experts": "Shippingtech Experts",
        "Logisticstech Experts": "Logisticstech Experts",
        "Supplychaintech Experts": "Supplychaintech Experts",
        "Warehousetech Experts": "Warehousetech Experts",
        "Retailtech Experts": "Retailtech Experts",
        "Ecommercetech Experts": "Ecommercetech Experts",
        "Marketplacetech Experts": "Marketplacetech Experts",
        "Socialcommercetech Experts": "Socialcommercetech Experts",
        "Livestreamtech Experts": "Livestreamtech Experts",
        "Videotech Experts": "Videotech Experts",
        "Audiotech Experts": "Audiotech Experts",
        "Podcasttech Experts": "Podcasttech Experts",
        "Musictech Experts": "Musictech Experts",
        "Gamingtech Experts": "Gamingtech Experts",
        "E sportstech Experts": "E sportstech Experts",
        "Metaversetech Experts": "Metaversetech Experts",
        "VRtech Experts": "VRtech Experts",
        "ARtech Experts": "ARtech Experts",
        "MRtech Experts": "MRtech Experts",
        "XRtech Experts": "XRtech Experts",
        "Hologramtech Experts": "Hologramtech Experts",
        "Projectiontech Experts": "Projectiontech Experts",
        "Displaytech Experts": "Displaytech Experts",
        "Screentech Experts": "Screentech Experts",
        "Touchtech Experts": "Touchtech Experts",
        "Interfacetech Experts": "Interfacetech Experts",
        "UXtech Experts": "UXtech Experts",
        "UItech Experts": "UItech Experts",
        "Designtech Experts": "Designtech Experts",
        "Creativetech Experts": "Creativetech Experts",
        "Arttech Experts": "Arttech Experts",
        "Designertech Experts": "Designertech Experts",
        "Phototech Experts": "Phototech Experts",
        "Videographytech Experts": "Videographytech Experts",
        "Cinematographtech Experts": "Cinematographtech Experts",
        "Animationtech Experts": "Animationtech Experts",
        "GFXtech Experts": "GFXtech Experts",
        "VFXtech Experts": "VFXtech Experts",
        "Motiontech Experts": "Motiontech Experts",
        "3Dtech Experts": "3Dtech Experts",
        "Modelingtech Experts": "Modelingtech Experts",
        "Renderingtech Experts": "Renderingtech Experts",
        "Simtech Experts": "Simtech Experts",
        "Emulationtech Experts": "Emulationtech Experts",
        "Virtualizationtech Experts": "Virtualizationtech Experts",
        "Cloudtech Experts": "Cloudtech Experts",
        "Distributedtech Experts": "Distributedtech Experts",
        "Decentralizedtech Experts": "Decentralizedtech Experts",
        "Blockchaintech Experts": "Blockchaintech Experts",
        "DistributedLedgertech Experts": "DistributedLedgertech Experts",
        "Crytocurrencytech Experts": "Crytocurrencytech Experts",
        "DigitalAssettech Experts": "DigitalAssettech Experts",
        "NFTtech Experts": "NFTtech Experts",
        "Web3tech Experts": "Web3tech Experts",
        "DApptech Experts": "DApptech Experts",
        "SmartContracttech Experts": "SmartContracttech Experts",
        "DeFitech Experts": "DeFitech Experts",
        "CeFitech Experts": "CeFitech Experts",
        "TradFitech Experts": "TradFitech Experts",
        "FinServicetech Experts": "FinServicetech Experts",
        "Bankingtech Experts": "Bankingtech Experts",
        "Paymenttech Experts": "Paymenttech Experts",
        "DigitalPaymenttech Experts": "DigitalPaymenttech Experts",
        "MobilePaymenttech Experts": "MobilePaymenttech Experts",
        "Contactlesstech Experts": "Contactlesstech Experts",
        "NFCtech Experts": "NFCtech Experts",
        "RFIDtech Experts": "RFIDtech Experts",
        "Sensortech Experts": "Sensortech Experts",
        "IoTtech Experts": "IoTtech Experts",
        "IIoTtech Experts": "IIoTtech Experts",
        "Industry4_0tech Experts": "Industry4_0tech Experts",
        "SmartFactortech Experts": "SmartFactortech Experts",
        "Automationtech Experts": "Automationtech Experts",
        "Roboticstech Experts": "Roboticstech Experts",
        "Cobottech Experts": "Cobottech Experts",
        "AGVtech Experts": "AGVtech Experts",
        "AMRtech Experts": "AMRtech Experts",
        "Autonomousvehicletech Experts": "Autonomousvehicletech Experts",
        "Selfdrivingtech Experts": "Selfdrivingtech Experts",
        "Dronech Experts": "Dronech Experts",
        "UAVtech Experts": "UAVtech Experts",
        "RPVtech Experts": "RPVtech Experts",
        "UAVtech Experts": "UAVtech Experts"
      }
    }
  end

  # Additional Frappe utility methods
  def get_sidebar_settings
    # Return Frappe-style sidebar settings format
    # Values: 1 = show item, 0 = hide item
    render json: {
      'courses' => 1,
      'batches' => 1,
      'certifications' => 1,
      'jobs' => 1,
      'statistics' => 1,
      'notifications' => 1,
      'programming_exercises' => 1,
      'my_courses' => 1,
      'my_batches' => 1,
      'profile' => 1,
      'settings' => 1,
      'logout' => 1,
      'web_pages' => []
    }
  end

  def get_my_live_classes
    render json: {
      message: "Live classes feature coming soon",
      data: []
    }
  end

  def get_streak_info
    return render json: {
      current_streak: 0,
      longest_streak: 0,
      total_days: 0,
      last_activity_date: nil
    } unless current_user

    # Calculate streak based on lesson progress activity
    activity_dates = LessonProgress.where(user: current_user)
      .where('last_accessed_at >= ?', 30.days.ago)
      .order(last_accessed_at: :desc)
      .pluck(:last_accessed_at)
      .map(&:to_date)
      .uniq

    current_streak = calculate_current_streak(activity_dates)
    longest_streak = calculate_longest_streak(activity_dates)
    total_days = activity_dates.count
    last_activity_date = activity_dates.first

    render json: {
      current_streak: current_streak,
      longest_streak: longest_streak,
      total_days: total_days,
      last_activity_date: last_activity_date
    }
  end

  private

  def calculate_current_streak(dates)
    return 0 if dates.empty?

    streak = 0
    current_date = Date.today

    dates.each do |date|
      if date == current_date
        streak += 1
        current_date -= 1
      elsif date == current_date - 1
        streak += 1
        current_date -= 1
      else
        break
      end
    end

    streak
  end

  def calculate_longest_streak(dates)
    return 0 if dates.empty?

    longest_streak = 0
    current_streak = 0
    previous_date = nil

    dates.sort.each do |date|
      if previous_date && (date == previous_date + 1 || date == previous_date)
        current_streak += 1
      else
        current_streak = 1
      end

      longest_streak = [longest_streak, current_streak].max
      previous_date = date
    end

    longest_streak
  end

  def get_my_courses
    return render json: [] unless current_user

    enrollments = current_user.enrollments.includes(:course)

    courses_data = enrollments.map do |enrollment|
      course = enrollment.course
      {
        name: course.id,
        title: course.title,
        progress: calculate_course_progress(current_user, course),
        status: enrollment.completed? ? 'Completed' : 'In Progress',
        enrollment_date: enrollment.created_at.strftime('%Y-%m-%d'),
        completion_date: enrollment.completed? ? Date.today.strftime('%Y-%m-%d') : nil,
        course_id: course.id,
        instructor: course.instructor&.full_name,
        tags: course.tags&.split(',') || [],
        category: course.category,
        image: course.image
      }
    end

    render json: courses_data
  end

  private

  def calculate_course_progress(user, course)
    total_lessons = course.lessons.count
    return 0 if total_lessons == 0

    completed_lessons = LessonProgress.joins(:lesson)
      .where(user: user, lessons: { course: course }, completed: true)
      .count

    ((completed_lessons.to_f / total_lessons) * 100).round(2)
  end

  def get_my_batches
    return render json: [] unless current_user

    batch_enrollments = current_user.batch_enrollments.includes(:batch, :course)

    batches_data = batch_enrollments.map do |enrollment|
      batch = enrollment.batch
      course = batch.course

      {
        name: batch.name,
        title: course&.title || batch.name,
        batch_id: batch.id,
        course_id: course&.id,
        start_date: batch.start_date&.strftime('%Y-%m-%d'),
        end_date: batch.end_date&.strftime('%Y-%m-%d'),
        status: batch_status(enrollment),
        joined_at: enrollment.created_at.strftime('%Y-%m-%d'),
        instructor: batch.instructor&.full_name,
        description: batch.description,
        max_students: batch.max_students,
        current_students: batch.batch_enrollments.count
      }
    end

    render json: batches_data
  end

  private

  def batch_status(enrollment)
    batch = enrollment.batch
    return 'Completed' if enrollment.completed?
    return 'Not Started' if batch.start_date > Date.today
    return 'Active' if batch.end_date >= Date.today
    'Ended'
  end

  def get_upcoming_evals
    return render json: [] unless current_user

    # Get quizzes for user's courses (mock implementation for now)
    user_courses = current_user.enrollments.pluck(:course_id)
    quizzes = Quiz.where(course_id: user_courses)
      .order(:created_at)
      .limit(10)

    evals_data = quizzes.map do |quiz|
      {
        course: quiz.course.title,
        course_id: quiz.course.id,
        quiz: quiz.title,
        quiz_id: quiz.id,
        scheduled_date: Date.today.strftime('%Y-%m-%d'), # Mock scheduled date
        duration: 30,
        max_attempts: 3,
        passing_percentage: quiz.passing_percentage || 70,
        questions_count: 5 # Mock question count
      }
    end

    render json: evals_data
  end

  private

  def authenticate_user_from_token!
    token = request.headers['Authorization']&.split(' ')&.last
    Rails.logger.info "Authenticating with token: #{token&.first(20)}..."
    return unless token

    begin
      decoded = JWT.decode(token, ENV.fetch('DEVISE_JWT_SECRET_KEY', Rails.application.secret_key_base), true, { algorithm: 'HS256' })
      payload = decoded[0]
      Rails.logger.info "Decoded payload: #{payload}"
      user = User.find_by(id: payload['sub'], jti: payload['jti'])
      Rails.logger.info "Found user: #{user&.email}"

      if user && payload['exp'] > Time.now.to_i
        @current_user = user
        Rails.logger.info "Authentication successful for #{user.email}"
      else
        Rails.logger.info "Authentication failed - user not found or token expired"
      end
    rescue JWT::DecodeError, JWT::ExpiredSignature => e
      Rails.logger.info "JWT decode error: #{e.message}"
      # Token is invalid or expired
      nil
    end
  end

  def current_user
    @current_user
  end
end