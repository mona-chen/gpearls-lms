module Certifications
  class AdminEvalsService
    def self.call(params = {})
      new(params).call
    end

    def initialize(params = {})
      @params = params
    end

    def call
      # Get certifications that need admin evaluation/review
      # This includes certifications in 'Under Review' status or other pending states
      evaluations = Certification.where(status: [ "Under Review", "Submitted" ])
                                 .includes(:user, :course, :category, :evaluator)
                                 .order(created_at: :desc)

      # Apply filters if provided
      if @params[:status].present?
        evaluations = evaluations.where(status: @params[:status])
      end

      if @params[:evaluator].present?
        evaluations = evaluations.where(evaluator_id: @params[:evaluator])
      end

      if @params[:course].present?
        evaluations = evaluations.where(course_id: @params[:course])
      end

      evaluations_data = evaluations.map do |evaluation|
        evaluation.to_frappe_format.merge(
          "evaluation_details" => {
            "submitted_at" => evaluation.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "last_modified" => evaluation.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
            "days_pending" => (Date.current - evaluation.created_at.to_date).to_i
          }
        )
      end

      { "data" => evaluations_data }
    end
  end
end
