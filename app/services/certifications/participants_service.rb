module Certifications
  class ParticipantsService
    def self.call(params = {})
      new(params).call
    end

    def initialize(params = {})
      @params = params
    end

    def call
      participants = Certification.published.includes(:user, :course, :category)

      # Apply filters from request
      if @params[:filters].present?
        filters = @params[:filters].respond_to?(:to_unsafe_h) ? @params[:filters].to_unsafe_h : @params[:filters]
        participants = participants.where(status: filters["status"]) if filters["status"].present?
        participants = participants.where(course_id: Course.find_by(title: filters["course"])&.id) if filters["course"].present?
        participants = participants.where(category: CertificationCategory.find_by(name: filters["category"])&.id) if filters["category"].present?
      end

      # Apply pagination
      limit = @params[:limit] || 20
      offset = @params[:start] || 0
      participants = participants.limit(limit).offset(offset)

      participants_data = participants.map do |certification|
        {
          name: certification.user&.full_name,
          certification_id: certification.id,
          user_id: certification.user_id,
          user_email: certification.user&.email,
          course_id: certification.course_id,
          course_title: certification.course&.title,
          category: certification.category&.name,
          evaluator: certification.evaluator&.full_name,
          status: certification.status,
          certificate_number: certification.certificate_number,
          issued_at: certification.issued_at&.strftime("%Y-%m-%d"),
          creation: certification.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          modified: certification.updated_at.strftime("%Y-%m-%d %H:%M:%S")
        }
      end

      { "data" => participants_data }
    end
  end
end
