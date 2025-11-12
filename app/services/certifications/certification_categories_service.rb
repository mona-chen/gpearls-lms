module Certifications
  class CertificationCategoriesService
    def self.call
      new.call
    end

    def call
      categories = CertificationCategory.enabled.by_name

      categories_data = categories.map do |category|
        category.to_frappe_format
      end

      { "data" => categories_data }
    end
  end
end
