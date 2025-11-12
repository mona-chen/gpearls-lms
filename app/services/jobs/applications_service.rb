module Jobs
  class ApplicationsService
    def self.cancel_request(user, job_opportunity_id)
      return { success: false, error: "User not authenticated" } unless user

      job_application = JobApplication.find_by(
        user: user,
        job_opportunity_id: job_opportunity_id
      )

      return { success: false, error: "Application not found" } unless job_application

      # Only allow cancellation if application is still pending
      unless job_application.status == "Applied"
        return { success: false, error: "Cannot cancel application in current status" }
      end

      if job_application.update(status: "Cancelled")
        { success: true, message: "Job application cancelled successfully" }
      else
        { success: false, error: job_application.errors.full_messages.join(", ") }
      end
    rescue => e
      { success: false, error: "Failed to cancel job application: #{e.message}" }
    end

    def self.create_request(user, job_opportunity_id, application_data = {})
      return { success: false, error: "User not authenticated" } unless user

      job_opportunity = JobOpportunity.find_by(id: job_opportunity_id)
      return { success: false, error: "Job opportunity not found" } unless job_opportunity

      # Check if user already applied
      existing_application = JobApplication.find_by(
        user: user,
        job_opportunity: job_opportunity
      )

      if existing_application
        return { success: false, error: "You have already applied for this job" }
      end

      # Create new application
      application = JobApplication.new(
        user: user,
        job_opportunity: job_opportunity,
        status: "Applied",
        cover_letter: application_data[:cover_letter],
        resume_url: application_data[:resume_url],
        portfolio_url: application_data[:portfolio_url],
        linkedin_url: application_data[:linkedin_url],
        github_url: application_data[:github_url],
        expected_salary: application_data[:expected_salary],
        availability_date: application_data[:availability_date] ? Date.parse(application_data[:availability_date]) : nil
      )

      if application.save
        { success: true, message: "Job application submitted successfully", application: application }
      else
        { success: false, error: application.errors.full_messages.join(", ") }
      end
    rescue => e
      { success: false, error: "Failed to create job application: #{e.message}" }
    end

    def self.has_requested(user, job_opportunity_id)
      return false unless user

      JobApplication.exists?(
        user: user,
        job_opportunity_id: job_opportunity_id
      )
    end

    def self.capture_interest(user, job_opportunity_id, interest_data = {})
      return { success: false, error: "User not authenticated" } unless user

      job_opportunity = JobOpportunity.find_by(id: job_opportunity_id)
      return { success: false, error: "Job opportunity not found" } unless job_opportunity

      # Create or update interest record
      interest = JobInterest.find_or_initialize_by(
        user: user,
        job_opportunity: job_opportunity
      )

      interest.interested_at = Time.current
      interest.source = interest_data[:source] || "website"
      interest.notes = interest_data[:notes]

      if interest.save
        { success: true, message: "Interest captured successfully" }
      else
        { success: false, error: interest.errors.full_messages.join(", ") }
      end
    rescue => e
      { success: false, error: "Failed to capture interest: #{e.message}" }
    end

    def self.capture_user_persona(user, persona_data = {})
      return { success: false, error: "User not authenticated" } unless user

      # Update user persona/profile information
      update_data = {}

      # Map persona fields to user attributes
      update_data[:job_title] = persona_data[:job_title] if persona_data[:job_title].present?
      update_data[:experience_years] = persona_data[:experience_years] if persona_data[:experience_years].present?
      update_data[:skills] = persona_data[:skills] if persona_data[:skills].present?
      update_data[:preferred_job_types] = persona_data[:preferred_job_types] if persona_data[:preferred_job_types].present?
      update_data[:preferred_locations] = persona_data[:preferred_locations] if persona_data[:preferred_locations].present?
      update_data[:salary_expectation_min] = persona_data[:salary_expectation_min] if persona_data[:salary_expectation_min].present?
      update_data[:salary_expectation_max] = persona_data[:salary_expectation_max] if persona_data[:salary_expectation_max].present?
      update_data[:remote_work_preference] = persona_data[:remote_work_preference] if persona_data[:remote_work_preference].present?

      if update_data.any?
        user.update!(update_data)
        { success: true, message: "User persona updated successfully" }
      else
        { success: false, error: "No persona data provided" }
      end
    rescue => e
      { success: false, error: "Failed to capture user persona: #{e.message}" }
    end
  end
end
