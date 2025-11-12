module Analytics
  class ChartService
    def self.call(chart_name = nil)
      if chart_name.present?
        get_chart_data(chart_name)
      else
        get_all_charts()
      end
    end

    def self.get_all_charts
      {
        "New Signups" => {
          chart_type: "line",
          data_points: get_new_signups_data
        },
        "Course Enrollments" => {
          chart_type: "bar",
          data_points: get_course_enrollments_data
        },
        "Certification" => {
          chart_type: "pie",
          data_points: get_certification_data
        }
      }
    end

    def self.get_chart_data(chart_name)
      case chart_name
      when "New Signups"
        get_new_signups_data
      when "Course Enrollments"
        get_course_enrollments_data
      when "Certification"
        get_certification_data
      else
        []
      end
    end

    private

    def self.get_new_signups_data
      signups = User.where("created_at >= ?", 7.days.ago)
                    .group("DATE(created_at)")
                    .count

      (6.downto(0)).map do |days_ago|
        date = Date.today - days_ago
        {
          date: date,
          count: signups[date.to_s] || 0
        }
      end
    end

    def self.get_course_enrollments_data
      enrollments = Enrollment.where("created_at >= ?", 7.days.ago)
                              .group("DATE(created_at)")
                              .count

      (6.downto(0)).map do |days_ago|
        date = Date.today - days_ago
        {
          date: date,
          count: enrollments[date.to_s] || 0
        }
      end
    end

    def self.get_certification_data
      issued_certificates = Certificate.where(status: "Issued").count
      draft_certificates = Certificate.where(status: "Draft").count

      [
        { label: "Issued", count: issued_certificates },
        { label: "Draft", count: draft_certificates }
      ]
    end
  end
end
