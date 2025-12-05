module Jobs
  class OpportunitiesService
    def self.call(params = {})
      new(params).call
    end

    def initialize(params = {})
      @params = params
    end

    def call
      opportunities = JobOpportunity.includes(:company)

      # Apply filters from request
      if @params[:filters].present?
        filters = @params[:filters].to_unsafe_h
        opportunities = opportunities.where(status: filters["status"]) if filters["status"].present?
        opportunities = opportunities.where(job_type: filters["job_type"]) if filters["job_type"].present?
        opportunities = opportunities.where(location: filters["location"]) if filters["location"].present?
      end

      # Apply search
      if @params[:search].present?
        opportunities = opportunities.where("title ILIKE ? OR description ILIKE ?",
                                         "%#{@params[:search]}%", "%#{@params[:search]}%")
      end

      # Apply pagination
      limit = @params[:limit] || 20
      offset = @params[:start] || 0
      opportunities = opportunities.limit(limit).offset(offset)

      opportunities_data = opportunities.map do |job|
        {
          name: job.title,
          title: job.title,
          job_id: job.id,
          company: job.company&.name,
          location: job.location,
          job_type: job.job_type,
          status: job.status,
          description: job.description,
          requirements: job.requirements,
          salary_min: job.salary_min,
          salary_max: job.salary_max,
          application_deadline: job.application_deadline&.strftime("%Y-%m-%d"),
          creation: job.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          modified: job.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
          application_count: job.job_applications.count
        }
      end

      opportunities_data
    end
  end
end
