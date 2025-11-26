class Api::JobOpportunitiesController < Api::BaseController
  skip_before_action :authenticate_user!, only: [ :index, :show ]

  def get_job_opportunities
    jobs = JobOpportunity.where(published: true)
                       .order(created_at: :desc)
                       .limit(20)

    render json: jobs.map do |job|
      {
        name: job.id,
        job_title: job.job_title,
        location: job.location,
        country: job.country,
        type: job.type,
        work_mode: job.work_mode,
        company_name: job.company_name,
        company_logo: job.company_logo,
        company_website: job.company_website,
        description: job.description,
        creation: job.created_at,
        posted_by: job.user&.full_name
      }
    end
  end

  def get_job_details
    job = JobOpportunity.find(params[:job_id])
    return render json: { error: "Job not found" }, status: :not_found unless job

    unless job.published
      return render json: { error: "Job not available" }, status: :forbidden
    end

    job_data = {
      name: job.id,
      job_title: job.job_title,
      location: job.location,
      country: job.country,
      type: job.type,
      work_mode: job.work_mode,
      company_name: job.company_name,
      company_logo: job.company_logo,
      company_website: job.company_website,
      description: job.description,
      creation: job.created_at,
      posted_by: job.user&.full_name,
      posted_by_image: job.user&.user_image,
      is_applied: current_user ? job.job_applications.exists?(user: current_user) : false
    }

    render json: job_data
  end

  def apply_job
    job = JobOpportunity.find(params[:job_id])
    return render json: { error: "Job not found" }, status: :not_found unless job

    return render json: { error: "Already applied" }, status: :conflict if job.job_applications.exists?(user: current_user)

    application = JobApplication.create!(
      job_opportunity: job,
      user: current_user,
      status: "Applied"
    )

    render json: {
      success: true,
      application_id: application.id,
      message: "Application submitted successfully"
    }
  end
end
