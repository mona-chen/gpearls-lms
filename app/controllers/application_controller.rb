class ApplicationController < ActionController::API
  include ActionController::Cookies
  include Devise::Controllers::Helpers

  protected

  def authenticate_user!
    if user_signed_in?
      @current_user = current_user
    else
      render json: { error: 'Not Authorized' }, status: :unauthorized
    end
  end

  def current_user
    @current_user ||= warden.authenticate(scope: :user)
  end

  def user_signed_in?
    !!current_user
  end

  def warden
    request.env['warden']
  end

  # Strong parameter methods for common use cases
  def pagination_params
    params.permit(:page, :per_page)
  end

  def search_params
    params.permit(:search, :q)
  end

  def filter_params
    params.permit(:status, :category, :type, :enrolled, :created, :certification, :title,
                  :my_batches, :my_cohorts, :starting_soon, :paid, :course_id, :instructor_id,
                  :date_range, :timeframe, :chart_name, :order_by, :reference, :currency,
                  :method_type, :item_type, :item_id, :payment_method, :amount, :reason,
                  :start_date, :end_date, :template, :lesson_id, :file, :doctype, :docname,
                  :file_url, :report_config, :format, :course_id, :subgroup, :invite_code,
                  :request_id, :user_id, :role, :member_type, :source, :assessment_type,
                  :assessment_name, :due_date, :max_marks, :reference_doctype, :reference_docname,
                  :date, :start_time, :end_time, :milestone, :scorm_data, :element, :value)
  end

  def course_params
    params.permit(:title, :description, :short_introduction, :video_link, :image,
                  :price, :currency, :enable_certification, :certificate_template,
                  :instructor_id, :category, :tags, :published, :featured, :upcoming,
                  :paid_certificate, :evaluator_id, :timezone, :card_gradient,
                  :disable_self_learning, :published_on, :workflow_state)
  end

  def user_params
    params.permit(:email, :username, :full_name, :profile_image, :status, :role,
                  :country, :timezone, :user_category, :verify_terms, :bio,
                  :linkedin_profile, :github_profile, :website, :phone)
  end

  def payment_params
    params.permit(:amount, :currency, :payment_method, :item_type, :item_id,
                  :reference, :description, :success_url, :cancel_url, :webhook_url)
  end

  def quiz_params
    params.permit(:title, :description, :course_id, :lesson_id, :passing_score,
                  :time_limit, :max_attempts, :show_answers, :randomize_questions,
                  :questions_attributes => [:id, :question, :question_type, :options, :correct_answer, :explanation, :points])
  end

  def assignment_params
    params.permit(:title, :description, :course_id, :lesson_id, :due_date,
                  :max_marks, :instructions, :file_required, :allow_late_submission)
  end

  def certificate_params
    params.permit(:course_id, :user_id, :evaluator_id, :status, :issue_date,
                  :expiry_date, :template, :custom_fields, :evaluation_score,
                  :evaluation_feedback, :download_count)
  end

  def scorm_params
    params.permit(:lesson_id, :file, :title, :description)
  end

  def zoom_params
    params.permit(:title, :description, :start_time, :duration, :timezone,
                  :zoom_account, :meeting_id, :password, :start_url, :join_url)
  end

  def cohort_params
    params.permit(:title, :description, :course_id, :instructor_id, :start_date,
                  :end_date, :max_students, :is_paid, :price, :currency, :status,
                  :invite_code_required, :slug, :image, :tags, :featured)
  end

  def batch_params
    params.permit(:title, :description, :course_id, :instructor_id, :start_date,
                  :end_date, :max_students, :price, :currency, :category, :published,
                  :evaluation_date, :certificate_template, :zoom_account, :source,
                  :meta, :workflow_state)
  end
end
