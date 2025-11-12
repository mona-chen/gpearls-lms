module Cohorts
  class CohortService
    def self.get_available_cohorts(user = nil)
      query = Cohort.includes(:course, :instructor, :cohort_subgroups)
                      .where(status: %w[Upcoming Live])
                      .order(created_at: :desc)

      if user
        # Exclude cohorts user is already enrolled in
        enrolled_cohort_ids = user.enrollments.where.not(cohort_id: nil).pluck(:cohort_id)
        query = query.where.not(id: enrolled_cohort_ids)
      end

      query
    end

    def self.get_user_cohorts(user, status_filter = nil)
      query = Cohort.includes(:course, :instructor, :cohort_subgroups)
                      .joins(:enrollments)
                      .where(enrollments: { user: user })
                      .order(created_at: :desc)

      case status_filter
      when "active"
        query = query.where(cohorts: { status: "Live" })
      when "upcoming"
        query = query.where(cohorts: { status: "Upcoming" })
      when "completed"
        query = query.where(cohorts: { status: "Completed" })
      end

      query
    end

    def self.join_cohort(user, cohort, subgroup, invite_code = nil)
      # Validate inputs
      return { success: false, error: "Invalid cohort" } unless cohort
      return { success: false, error: "Invalid subgroup" } unless subgroup

      # Check invite code if provided
      if invite_code.present? && subgroup.invite_code != invite_code
        return { success: false, error: "Invalid invite code" }
      end

      # Check if user is already a member
      if cohort.enrollments.exists?(user: user, cohort_subgroup: subgroup)
        return { success: false, error: "Already a member of this subgroup" }
      end

      # Create join request
      join_request = CohortJoinRequest.create_request(user, cohort, subgroup)
      if join_request
        { success: true, request: join_request.to_frappe_format }
      else
        { success: false, error: "Failed to create join request" }
      end
    end

    def self.approve_join_request(join_request, approved_by = nil)
      return { success: false, error: "Invalid request" } unless join_request
      return { success: false, error: "Request not pending" } unless join_request.pending?

      subgroup = join_request.cohort_subgroup
      cohort = join_request.cohort

      # Create enrollment if request approved
      if join_request.approve(approved_by: approved_by)
        { success: true, message: "Join request approved" }
      else
        { success: false, error: "Failed to approve request" }
      end
    end

    def self.reject_join_request(join_request, reason = nil, rejected_by = nil)
      return { success: false, error: "Invalid request" } unless join_request
      return { success: false, error: "Request not pending" } unless join_request.pending?

      if join_request.reject(reason: reason, rejected_by: rejected_by)
        { success: true, message: "Join request rejected" }
      else
        { success: false, error: "Failed to reject request" }
      end
    end

    def self.undo_reject_join_request(join_request, undone_by = nil)
      return { success: false, error: "Invalid request" } unless join_request
      return { success: false, error: "Request not rejected" } unless join_request.rejected?

      if join_request.undo_reject(undone_by: undone_by)
        { success: true, message: "Join request rejection undone" }
      else
        { success: false, error: "Failed to undo rejection" }
      end
    end

    def self.calculate_user_progress_for_cohort(user, cohort)
      return 0 unless user && cohort && cohort.course

      total_lessons = cohort.course.lessons.count
      return 0 if total_lessons == 0

      completed_lessons = user.lesson_progress
                              .joins(lesson: :chapter)
                              .where(chapters: { course: cohort.course })
                              .where(status: "Complete")
                              .count

      (completed_lessons.to_f / total_lessons * 100).round(2)
    end

    def self.get_last_activity_for_cohort(user, cohort)
      return nil unless user && cohort && cohort.course

      activity = user.lesson_progress
                   .joins(lesson: :chapter)
                   .where(chapters: { course: cohort.course })
                   .order(:updated_at)
                   .last

      activity&.updated_at
    end
  end
end
