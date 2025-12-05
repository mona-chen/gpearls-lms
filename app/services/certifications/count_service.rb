module Certifications
  class CountService
    def self.call
      Certificate.where.not(student_id: nil).distinct.count(:student_id)
    end
  end
end
