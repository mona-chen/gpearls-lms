module Api
  module Compatibility
    class AnalyticsController < BaseController
      def get_streak_info
        streak_data = Analytics::StreakInfoService.call(current_user)
        render json: { data: streak_data }
      end

      def get_heatmap_data
        heatmap_data = Analytics::HeatmapDataService.call(current_user)
        render json: { data: heatmap_data }
      end

      def get_chart_details
        chart_details = {
          'New Signups' => {
            chart_type: 'line',
            data_points: get_new_signups_data
          },
          'Course Enrollments' => {
            chart_type: 'bar',
            data_points: get_course_enrollments_data
          },
          'Certification' => {
            chart_type: 'pie',
            data_points: get_certification_data
          }
        }

        render json: { data: chart_details }
      end

      def get_chart_data
        chart_name = params[:chart_name]

        data = case chart_name
               when 'New Signups'
                 get_new_signups_data
               when 'Course Enrollments'
                 get_course_enrollments_data
               when 'Certification'
                 get_certification_data
               else
                 []
               end

        render json: { data: data }
      end

      def get_statistics
        stats = {
          total_users: User.count,
          total_courses: Course.count,
          total_enrollments: Enrollment.count,
          total_batches: Batch.count,
          total_certificates: Certificate.count,
          published_courses: Course.where(published: true).count,
          active_batches: Batch.where('start_date <= ? AND end_date >= ?', Date.today, Date.today).count
        }

        render json: { data: stats }
      end

      private

      def get_new_signups_data
        signups = User.where('created_at >= ?', 7.days.ago)
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

      def get_course_enrollments_data
        enrollments = Enrollment.where('created_at >= ?', 7.days.ago)
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

      def get_certification_data
        total_certificates = Certificate.count
        published_certificates = Certificate.where(published: true).count
        pending_certificates = total_certificates - published_certificates

        [
          { label: 'Published', count: published_certificates },
          { label: 'Pending', count: pending_certificates }
        ]
      end
    end
  end
end