class Api::OnboardingController < Api::BaseController
  before_action :authenticate_user!

  # GET /api/onboarding/status
  def status
    onboarding_status = Onboarding::OnboardingService.call(user: current_user)
    render json: onboarding_status
  end

  # GET /api/onboarding/first-course
  def first_course
    course_name = Onboarding::OnboardingService.new(current_user).get_first_course
    render json: { first_course: course_name }
  end

  # GET /api/onboarding/first-batch
  def first_batch
    batch_name = Onboarding::OnboardingService.new(current_user).get_first_batch
    render json: { first_batch: batch_name }
  end

  # Frappe compatibility methods
  def handle_method
    case params[:method_path]
    when "lms.onboarding.is_onboarding_complete"
      render json: Onboarding::OnboardingService.call(user: current_user)
    when "lms.onboarding.get_first_course"
      course_name = Onboarding::OnboardingService.new(current_user).get_first_course
      render json: course_name || {}
    when "lms.onboarding.get_first_batch"
      batch_name = Onboarding::OnboardingService.new(current_user).get_first_batch
      render json: batch_name || {}
    when "frappe.client.set_value"
      handle_set_value
    else
      render json: { error: "Unknown method" }, status: :not_found
    end
  end

  private

  def handle_set_value
    if params[:doctype] == "LMS Settings" && params[:fieldname] == "is_onboarding_complete"
      LmsSetting.set_onboarding_complete(params[:value] == 1)
      render json: { success: true }
    else
      render json: { error: "Invalid parameters" }, status: :unprocessable_entity
    end
  end
end
