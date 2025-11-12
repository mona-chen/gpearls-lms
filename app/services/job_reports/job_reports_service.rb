module JobReports
  class JobReportsService
    def self.report_job(job_opportunity, user, reason, description = nil)
      new(job_opportunity, user, reason, description).create_report
    end

    def self.get_pending_reports
      JobReport.where(status: :pending)
    end

    def self.resolve_report(report_id, admin_user, action)
      report = JobReport.find(report_id)
      report.update!(
        status: :resolved,
        modified_by: admin_user,
        resolution_action: action,
        modified: Time.current
      )

      # If the action is to remove the job, mark it as inactive
      if action == "remove_job"
        job_opportunity = JobOpportunity.find_by(name: report.job_opportunity)
        job_opportunity.update!(published: false) if job_opportunity
      end

      report
    end

    def initialize(job_opportunity, user, reason, description)
      @job_opportunity = job_opportunity
      @user = user
      @reason = reason
      @description = description
    end

    def create_report
      # Check if user has already reported this job
      existing_report = JobReport.find_by(
        job_opportunity: @job_opportunity,
        reported_by: @user
      )

      if existing_report
        existing_report.update!(
          reason: @reason,
          description: @description,
          status: :pending # Re-open if it was resolved
        )
        existing_report
      else
        JobReport.create!(
          job_opportunity: @job_opportunity,
          reported_by: @user,
          reason: @reason,
          description: @description,
          status: :pending
        )
      end
    end
  end
end
