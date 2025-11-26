class OnboardingMailer < ApplicationMailer
  def welcome_email(user, onboarding_checklist)
    @user = user
    @user_name = user.full_name || user.email
    @checklist = onboarding_checklist
    @first_course = Onboarding::OnboardingService.get_first_course
    @platform_name = Rails.application.config.app_name || "LMS Platform"

    mail(
      to: user.email,
      subject: "Welcome to #{@platform_name}! Let's get you started 🚀"
    )
  end

  def onboarding_complete(user)
    @user = user
    @user_name = user.full_name || user.email
    @platform_name = Rails.application.config.app_name || "LMS Platform"
    @achievements = get_user_achievements(user)
    @next_recommendations = Onboarding::OnboardingService.get_personalized_recommendations(user)

    mail(
      to: user.email,
      subject: "🎉 Congratulations! You've completed your onboarding"
    )
  end

  def onboarding_reminder(user, days_since_signup)
    @user = user
    @user_name = user.full_name || user.email
    @days_since_signup = days_since_signup
    @checklist = Onboarding::OnboardingService.get_onboarding_checklist(user)
    @progress = Onboarding::OnboardingService.check_onboarding_status(user)[:onboarding_progress]

    mail(
      to: user.email,
      subject: "Continue your learning journey - #{@progress}% complete!"
    )
  end

  def profile_completion_reminder(user)
    @user = user
    @user_name = user.full_name || user.email
    @missing_fields = get_missing_profile_fields(user)
    @profile_url = Rails.application.routes.url_helpers.profile_url

    mail(
      to: user.email,
      subject: "Complete your profile to unlock personalized recommendations"
    )
  end

  private

  def get_user_achievements(user)
    achievements = []

    achievements << "✅ Completed profile setup" if profile_completed?(user)
    achievements << "📚 Enrolled in #{user.enrollments.count} course(s)" if user.enrollments.exists?
    achievements << "🧩 Completed #{user.quiz_submissions.count} quiz(es)" if user.quiz_submissions.exists?
    achievements << "👥 Joined learning batches" if user.batch_enrollments.exists?
    achievements << "📝 Submitted assignments" if has_submitted_assignment?(user)

    achievements
  end

  def get_missing_profile_fields(user)
    missing = []

    missing << "First Name" if user.first_name.blank?
    missing << "Last Name" if user.last_name.blank?
    missing << "Headline" if user.headline.blank?
    missing << "City" if user.city.blank?
    missing << "Profession" if user.profession.blank?

    missing
  end

  def profile_completed?(user)
    Onboarding::OnboardingService.send(:profile_completed?, user)
  end

  def has_submitted_assignment?(user)
    Onboarding::OnboardingService.send(:has_submitted_assignment?, user)
  end
end
