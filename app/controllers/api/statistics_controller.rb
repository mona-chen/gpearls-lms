class Api::StatisticsController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:chart_details, :course_completion_data]

  def chart_details
    details = {
      enrollments: Enrollment.count,
      courses: Course.where(published: true, upcoming: false).count,
      users: User.where(enabled: true).where.not(email: ['Administrator', 'Guest']).count,
      completions: Enrollment.where('progress >= ?', 100.0).count,
      certifications: Certificate.where(published: true).count
    }
    render json: details
  end

  def course_progress_distribution
    course = Course.find(params[:course])
    return render json: { error: 'Course not found' }, status: :not_found unless course

    all_progress = course.enrollments.pluck(:progress)
    average_progress = all_progress.sum.to_f / all_progress.size

    progress_distribution = [
      { category: '0-20%', count: all_progress.count { |p| p >= 0 && p < 20 } },
      { category: '20-40%', count: all_progress.count { |p| p >= 20 && p < 40 } },
      { category: '40-60%', count: all_progress.count { |p| p >= 40 && p < 60 } },
      { category: '60-80%', count: all_progress.count { |p| p >= 60 && p < 80 } },
      { category: '80-100%', count: all_progress.count { |p| p >= 80 && p <= 100 } }
    ]

    render json: {
      average_progress: average_progress.round(2),
      progress_distribution: progress_distribution
    }
  end

  def heatmap_data
    return render json: { error: 'Not authenticated' }, status: :unauthorized unless current_user

    # Get activity data for the last 200 days
    base_date = 200.days.ago.to_date
    activities = []

    # Lesson completions
    current_user.course_progresses.where(status: 'Complete', created_at: base_date..Date.today).each do |progress|
      activities << { date: progress.created_at.to_date, count: 1 }
    end

    # Quiz submissions
    current_user.quiz_submissions.where(created_at: base_date..Date.today).each do |submission|
      activities << { date: submission.created_at.to_date, count: 1 }
    end

    # Group by date
    grouped_activities = activities.group_by { |a| a[:date] }.transform_values { |v| v.sum { |a| a[:count] } }

    # Create heatmap data
    heatmap_data = []
    total_activities = 0

    (base_date..Date.today).each do |date|
      count = grouped_activities[date] || 0
      total_activities += count

      day_name = date.strftime('%a')
      unless heatmap_data.find { |h| h['name'] == day_name }
        heatmap_data << { 'name' => day_name, 'data' => [] }
      end

      day_data = heatmap_data.find { |h| h['name'] == day_name }
      day_data['data'] << {
        'date' => date.strftime('%Y-%m-%d'),
        'count' => count,
        'label' => "#{count} activities on #{date.strftime('%d %b')}"
      }
    end

    render json: {
      heatmap_data: heatmap_data,
      total_activities: total_activities,
      weeks: ((Date.today - base_date).to_i / 7.0).ceil
    }
  end
end