module Certifications
  class CategoriesService
    def self.call(params = {})
      new(params).call
    end

    def initialize(params = {})
      @params = params
    end

    def call
      categories = CertificationCategory.includes(:certifications)

      # Apply filters from request
      if @params[:filters].present?
        filters = @params[:filters].to_unsafe_h
        categories = categories.where(enabled: true) if filters["published"] == 1
      end

      # Apply pagination
      limit = @params[:limit] || 20
      offset = @params[:start] || 0
      categories = categories.limit(limit).offset(offset)

      categories_data = categories.map do |category|
        {
          name: category.name,
          title: category.name,
          category_id: category.id,
          description: category.description,
          enabled: category.enabled,
          creation: category.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          modified: category.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
          certification_count: category.certifications.count
        }
      end

      { "data" => categories_data }
    end
  end
end
