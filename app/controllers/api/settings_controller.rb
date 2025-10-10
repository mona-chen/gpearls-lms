class Api::SettingsController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:branding, :sidebar_settings, :index]

  def index
    render json: {
      app_name: 'LMS',
      version: '1.0.0',
      settings: Setting.all.map { |s| { key: s.key, value: s.value } }
    }
  end

  def sidebar_settings
    lms_settings = {
      'courses' => 1,
      'batches' => 1,
      'certifications' => 1,
      'jobs' => 1,
      'statistics' => 1,
      'notifications' => 1,
      'programming_exercises' => 1
    }

    # Add custom sidebar items if any
    lms_settings['web_pages'] = []

    render json: lms_settings
  end

  def lms_setting
    settings = {
      'allow_guest_access' => true,
      'enable_certification' => true,
      'enable_payments' => false,
      'enable_live_classes' => true,
      'enable_job_board' => true,
      'enable_discussions' => true,
      'enable_programs' => false
    }
    
    if params[:field]
      render json: settings[params[:field]] || false
    else
      render json: settings
    end
  end

  def branding
    branding = {
      app_name: 'Frappe LMS',
      app_logo: '/frontend/public/images/lms-logo.png',
      app_favicon: '/frontend/public/favicon.png',
      app_logo_dark: '/frontend/public/images/lms-logo.png',
      banner_image: '/frontend/public/images/lms.png',
      primary_color: '#1a73e8',
      secondary_color: '#34a853',
      text_color: '#202124',
      background_color: '#ffffff'
    }
    
    render json: branding
  end
end