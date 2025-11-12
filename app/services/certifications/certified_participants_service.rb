module Certifications
  class CertifiedParticipantsService
    def self.call(params = {})
      new(params).call
    end

    def initialize(params = {})
      @params = params
    end

    def call
      filters = {}

      # Apply filters from request
      if @params[:category].present?
        filters[:category] = @params[:category]
      end

      if @params[:course].present?
        filters[:course] = @params[:course]
      end

      participants = Certification.get_certified_participants(filters)

      { "data" => participants }
    end
  end
end
