module Onboarding
  class OnboardingService
    def self.call(user:)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      is_onboarding_complete
    end

    def get_first_course
      Course.select(:title).order(:created_at).first&.title
    end

    def get_first_batch
      Batch.select(:title).order(:created_at).first&.title
    end

    private

    def is_onboarding_complete
      if has_course_moderator_role?
        # Check if moderator has created content (exact Frappe logic)
        course_created = Course.exists?
        chapter_created = CourseChapter.exists?
        lesson_created = CourseLesson.exists?

        # If moderator has created content, consider onboarding complete
        is_onboarding_complete = course_created && chapter_created && lesson_created

        first_course = Course.order(:created_at).first&.name

        {
          is_onboarded: is_onboarding_complete,
          course_created: course_created,
          chapter_created: chapter_created,
          lesson_created: lesson_created,
          first_course: first_course,
          has_moderator_role: has_course_moderator_role?
        }
      else
        # Non-moderators are always considered onboarded
        { is_onboarded: true }
      end
    end

    def has_course_moderator_role?
      return false unless @user

      # Check if user has Moderator role (exact Frappe logic)
      @user.has_role?("Moderator")
    end

    def self.has_course_moderator_role?(user = nil)
      user ||= User.current
      return false unless user

      user.has_role?("Moderator")
    end
  end
end
