module Certifications
  class CountService
    def self.call
      count = Certificate.where.not(student_id: nil).distinct.count(:student_id)

      {
        "count" => count
      }
    end
  end
end
