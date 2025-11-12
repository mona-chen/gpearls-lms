class Api::CohortsController < Api::BaseController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_cohort, only: [:show, :update, :destroy, :join, :leave, :subgroups, :join_requests, :statistics, :add_mentor, :remove_mentor, :add_staff, :remove_staff]
  before_action :require_cohort_instructor_or_admin!, only: [:update, :destroy, :add_mentor, :remove_mentor, :add_staff, :remove_staff, :join_requests, :statistics]

  # GET /api/cohorts
  def index
    cohorts = Cohort.includes(:course, :instructor, :cohort_subgroups)
                    .order(created_at: :desc)

    # Apply filters
    cohorts = cohorts.by_course(params[:course_id]) if params[:course_id].present?
    cohorts = cohorts.by_instructor(current_user) if params[:my_cohorts] == 'true'
    cohorts = cohorts.active if params[:status] == 'active'
    cohorts = cohorts.upcoming if params[:status] == 'upcoming'
    cohorts = cohorts.completed if params[:status] == 'completed'

    # Apply search
    if params[:search].present?
      cohorts = cohorts.where('cohorts.title ILIKE ?', "%#{params[:search]}%")
    end

    # Pagination
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    cohorts = cohorts.limit(per_page).offset((page.to_i - 1) * per_page)

    render json: {
      data: cohorts.map(&:to_frappe_format),
      pagination: {
        current_page: page.to_i,
        per_page: per_page.to_i,
        total_count: Cohort.count
      }
    }
  end

  # GET /api/cohorts/:id
  def show
    render json: @cohort.to_frappe_format
  end

  # POST /api/cohorts
  def create
    cohort = Cohort.new(cohort_params)
    cohort.instructor = current_user

    if cohort.save
      render json: cohort.to_frappe_format, status: :created
    else
      render json: { errors: cohort.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/cohorts/:id
  def update
    if @cohort.update(cohort_params)
      render json: @cohort.to_frappe_format
    else
      render json: { errors: @cohort.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/cohorts/:id
  def destroy
    ActiveRecord::Base.transaction do
      # Send cancellation notifications
      @cohort.enrollments.includes(:user).find_each do |enrollment|
        CohortMailer.cohort_cancelled(enrollment.user, @cohort, "Cohort deleted by instructor").deliver_later
      end

      @cohort.destroy
    end

    render json: { message: "Cohort deleted successfully" }
  end

  # POST /api/cohorts/:id/join
  def join
    subgroup_slug = params[:subgroup] || 'main'
    subgroup = @cohort.get_subgroup(subgroup_slug)

    if subgroup.nil?
      return render json: { error: "Subgroup not found" }, status: :not_found
    end

    invite_code = params[:invite_code]
    if subgroup.invite_code.present? && invite_code != subgroup.invite_code
      return render json: { error: "Invalid invite code" }, status: :forbidden
    end

    result = Cohorts::CohortService.join_cohort(current_user, @cohort, subgroup, invite_code: params[:invite_code])

    if result[:success]
      render json: result[:request], status: :created
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  # DELETE /api/cohorts/:id/leave
  def leave
    enrollment = @cohort.enrollments.find_by(user: current_user)
    return render json: { error: "Not enrolled in this cohort" }, status: :not_found unless enrollment

    reason = params[:reason] || "User requested to leave"
    enrollment.destroy

    CohortMailer.cohort_cancelled(current_user, @cohort, reason).deliver_later

    render json: { message: "Successfully left cohort" }
  end

  # GET /api/cohorts/:id/subgroups
  def subgroups
    subgroups = @cohort.get_subgroups(include_counts: true)
    render json: { data: subgroups.map(&:to_frappe_format) }
  end

  # POST /api/cohorts/:id/subgroups
  def create_subgroup
    subgroup_params = params.require(:subgroup).permit(:title, :description)
    subgroup = @cohort.cohort_subgroups.create!(subgroup_params)

    render json: subgroup.to_frappe_format, status: :created
  end

  # GET /api/cohorts/:id/join-requests
  def join_requests
    status_filter = params[:status]
    requests = CohortJoinRequest.by_cohort(@cohort).recent

    case status_filter
    when 'pending'
      requests = requests.pending
    when 'accepted'
      requests = requests.accepted
    when 'rejected'
      requests = requests.rejected
    end

    render json: {
      data: requests.includes(:user, :cohort_subgroup).map(&:to_frappe_format)
    }
  end

  # POST /api/cohorts/:id/join-requests/:request_id/approve
  def approve_join_request
    request = CohortJoinRequest.find(params[:request_id])
    return render json: { error: "Join request not found" }, status: :not_found unless request
    return render json: { error: "Request not for this cohort" }, status: :forbidden unless request.cohort == @cohort

    unless request.can_be_approved_by?(current_user)
      return render json: { error: "Unauthorized to approve requests" }, status: :forbidden
    end

    result = Cohorts::CohortService.approve_join_request(request, current_user.email)

    if result[:success]
      render json: request.to_frappe_format
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  # POST /api/cohorts/:id/join-requests/:request_id/reject
  def reject_join_request
    request = CohortJoinRequest.find(params[:request_id])
    return render json: { error: "Join request not found" }, status: :not_found unless request
    return render json: { error: "Request not for this cohort" }, status: :forbidden unless request.cohort == @cohort

    unless request.can_be_rejected_by?(current_user)
      return render json: { error: "Unauthorized to reject requests" }, status: :forbidden
    end

    reason = params[:reason]
    result = Cohorts::CohortService.reject_join_request(request, reason, current_user.email)

    if result[:success]
      render json: request.to_frappe_format
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  # POST /api/cohorts/:id/add-mentor
  def add_mentor
    user_id = params[:user_id]
    subgroup_slug = params[:subgroup] || 'main'

    user = User.find(user_id)
    subgroup = @cohort.get_subgroup(subgroup_slug)

    if user.nil? || subgroup.nil?
      return render json: { error: "User or subgroup not found" }, status: :not_found
    end

    result = Cohorts::CohortService.add_mentor_to_cohort(@cohort, user, subgroup: subgroup)

    if result[:success]
      CohortMailer.new_mentor_assigned(@cohort, user, subgroup).deliver_later
      render json: { message: result[:message] }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  # DELETE /api/cohorts/:id/remove-mentor
  def remove_mentor
    user_id = params[:user_id]
    user = User.find(user_id)

    if user.nil?
      return render json: { error: "User not found" }, status: :not_found
    end

    result = Cohorts::CohortService.remove_mentor_from_cohort(@cohort, user)

    if result[:success]
      render json: { message: result[:message] }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  # POST /api/cohorts/:id/add-staff
  def add_staff
    user_id = params[:user_id]
    role = params[:role] || 'Staff'

    user = User.find(user_id)
    return render json: { error: "User not found" }, status: :not_found unless user

    if @cohort.add_staff(user, role: role)
      render json: { message: "Staff member added successfully" }
    else
      render json: { error: "Unable to add staff member" }, status: :unprocessable_entity
    end
  end

  # DELETE /api/cohorts/:id/remove-staff
  def remove_staff
    user_id = params[:user_id]
    user = User.find(user_id)

    if user.nil?
      return render json: { error: "User not found" }, status: :not_found
    end

    if @cohort.remove_staff(user)
      render json: { message: "Staff member removed successfully" }
    else
      render json: { error: "Unable to remove staff member" }, status: :unprocessable_entity
    end
  end

  # GET /api/cohorts/:id/statistics
  def statistics
    render json: Cohorts::CohortService.get_cohort_statistics(@cohort)
  end

  # GET /api/cohorts/:id/members
  def members
    member_type = params[:type]
    members = @cohort.get_members(member_type: member_type)

    render json: {
      data: members.includes(:user).map do |enrollment|
        user = enrollment.user
        {
          enrollment: enrollment.to_frappe_format,
          user: {
            email: user.email,
            name: user.full_name,
            username: user.username,
            user_image: user.user_image
          },
          progress: Cohorts::CohortService.calculate_user_progress_for_cohort(user, @cohort.course),
          last_activity: Cohorts::CohortService.get_last_activity_for_cohort(user, @cohort.course)
        }
      end
    }
  end

  # GET /api/cohorts/my-enrollments
  def my_enrollments
    enrollments = current_user.enrollments.where.not(cohort_id: nil).includes(:cohort, :cohort_subgroup)

    render json: {
      data: enrollments.map do |enrollment|
        enrollment.to_frappe_format.merge(
        cohort_details: enrollment.cohort.to_frappe_format,
        subgroup_details: enrollment.cohort_subgroup&.to_frappe_format,
        progress: Cohorts::CohortService.calculate_user_progress_for_cohort(current_user, enrollment.cohort.course),
        upcoming_events: get_cohort_events(enrollment.cohort)
      )
      end
    }
  end

  private

  def set_cohort
    @cohort = Cohort.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Cohort not found" }, status: :not_found
  end

  def cohort_params
    params.require(:cohort).permit(
      :title,
      :description,
      :status,
      :begin_date,
      :end_date,
      :duration,
      :slug,
      cohort_web_pages_attributes: [:id, :slug, :title, :content, :scope, :template_html, :_destroy]
    )
  end

  def require_cohort_instructor_or_admin!
    return true if @cohort.instructor == current_user
    return true if @cohort.is_admin?(current_user)
    return true if current_user.has_role?('System Manager') || current_user.has_role?('Administrator')

    render json: { error: "Unauthorized" }, status: :forbidden
  end

  def calculate_user_progress(user, course)
    return 0 unless user && course

    total_lessons = course.lessons.count
    return 0 if total_lessons == 0

    completed_lessons = user.lesson_progress
                          .joins(lesson: :chapter)
                          .where(chapters: { course: course })
                          .where(status: 'Complete')
                          .count

    (completed_lessons.to_f / total_lessons * 100).round(2)
  end

  def get_last_activity(user, course)
    return nil unless user && course

    activity = user.lesson_progress
                     .joins(lesson: :chapter)
                     .where(chapters: { course: course })
                     .order(:updated_at)
                     .last

    activity&.updated_at
  end

  def get_cohort_events(cohort)
    # Return upcoming cohort events, discussions, etc.
    # This would integrate with discussion topics, live sessions, etc.
    []
  end

  def get_enrollment_trends(cohort)
    # Calculate enrollment trends over time
    enrollments_by_month = cohort.enrollments
                                 .group_by_month(:created_at, last: 12)
                                 .count

    {
      labels: enrollments_by_month.keys.map { |date| date.strftime('%B %Y') },
      data: enrollments_by_month.values
    }
  end

  def get_activity_metrics(cohort)
    # Calculate activity metrics
    total_lessons = cohort.course.lessons.count
    total_completions = cohort.enrollments.joins(user: :lesson_progress)
                                         .where(lesson_progresses: { status: 'Complete' })
                                         .distinct
                                         .count

    {
      total_lessons: total_lessons,
      total_completions: total_completions,
      average_completion_rate: total_lessons > 0 ? (total_completions.to_f / total_lessons * 100).round(2) : 0,
      active_members: cohort.enrollments.joins(user: :lesson_progress)
                                       .where('lesson_progresses.updated_at > ?', 7.days.ago)
                                       .distinct
                                       .count
    }
  end

  def get_mentor_performance(cohort)
    # Calculate mentor performance metrics
    cohort.cohort_mentors.includes(:user).map do |mentor|
      students = mentor.get_students
      active_students = students.select do |enrollment|
        enrollment.user.lesson_progress
                   .joins(lesson: :chapter)
                   .where(chapters: { course: cohort.course })
                   .where('lesson_progresses.updated_at > ?', 30.days.ago)
                   .exists?
      end

      {
        mentor: mentor.user.full_name,
        total_students: students.count,
        active_students: active_students.count,
        engagement_rate: students.count > 0 ? (active_students.count.to_f / students.count * 100).round(2) : 0
      }
    end
  end
end
