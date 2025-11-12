class CohortMailer < ApplicationMailer
  default from: Rails.application.credentials.dig(:email, :from) || 'noreply@lms.test'

  def cohort_started(cohort, user = nil)
    @cohort = cohort
    @user = user
    @subject = "Cohort Started: #{cohort.title}"

    if user
      mail(to: user.email, subject: @subject, template_name: 'cohort_started_individual')
    else
      # Send to all enrolled members
      member_emails = cohort.enrollments.joins(:user).pluck('users.email')
      mail(to: member_emails, subject: @subject, template_name: 'cohort_started')
    end
  end

  def cohort_completed(cohort, user = nil)
    @cohort = cohort
    @user = user
    @subject = "Cohort Completed: #{cohort.title}"

    if user
      mail(to: user.email, subject: @subject, template_name: 'cohort_completed_individual')
    else
      # Send to all enrolled members
      member_emails = cohort.enrollments.joins(:user).pluck('users.email')
      mail(to: member_emails, subject: @subject, template_name: 'cohort_completed')
    end
  end

  def cohort_cancelled(cohort, reason = nil)
    @cohort = cohort
    @reason = reason
    @subject = "Cohort Cancelled: #{cohort.title}"

    # Send to all enrolled members
    member_emails = cohort.enrollments.joins(:user).pluck('users.email')
    mail(to: member_emails, subject: @subject, template_name: 'cohort_cancelled')
  end

  def cohort_published(cohort)
    @cohort = cohort
    @subject = "New Cohort Available: #{cohort.title}"

    # Send to users who might be interested
    interested_users = get_interested_users(cohort)
    mail(to: interested_users.pluck(:email), subject: @subject, template_name: 'cohort_published')
  end

  def join_request_approved(user, cohort, subgroup)
    @user = user
    @cohort = cohort
    @subgroup = subgroup
    @subject = "Join Request Approved: #{cohort.title}"

    mail(to: user.email, subject: @subject, template_name: 'join_request_approved')
  end

  def join_request_rejected(user, cohort, subgroup, reason = nil)
    @user = user
    @cohort = cohort
    @subgroup = subgroup
    @reason = reason
    @subject = "Join Request Update: #{cohort.title}"

    mail(to: user.email, subject: @subject, template_name: 'join_request_rejected')
  end

  def new_join_request(join_request)
    @join_request = join_request
    @cohort = join_request.cohort
    @subgroup = join_request.cohort_subgroup
    @subject = "New Join Request: #{@cohort.title} - #{@subgroup.title}"

    # Send to cohort staff and mentors
    recipient_emails = get_recipient_emails(@cohort, @subgroup)
    mail(to: recipient_emails, subject: @subject, template_name: 'new_join_request')
  end

  def cohort_update(cohort, changes = {})
    @cohort = cohort
    @changes = changes
    @subject = "Cohort Update: #{cohort.title}"

    # Send to all enrolled members
    member_emails = cohort.enrollments.joins(:user).pluck('users.email')
    mail(to: member_emails, subject: @subject, template_name: 'cohort_update')
  end

  def new_mentor_assigned(cohort, mentor, subgroup)
    @cohort = cohort
    @mentor = mentor
    @subgroup = subgroup
    @subject = "New Mentor Assigned: #{cohort.title}"

    # Send to subgroup members
    member_emails = subgroup.enrollments.joins(:user).pluck('users.email')
    mail(to: member_emails, subject: @subject, template_name: 'new_mentor_assigned')
  end

  def cohort_announcement(cohort, announcement)
    @cohort = cohort
    @announcement = announcement
    @subject = "Announcement: #{announcement.title}"

    # Send to all enrolled members
    member_emails = cohort.enrollments.joins(:user).pluck('users.email')
    mail(to: member_emails, subject: @subject, template_name: 'cohort_announcement')
  end

  def weekly_digest(cohort, stats = {})
    @cohort = cohort
    @stats = stats
    @subject = "Weekly Digest: #{cohort.title}"

    # Send to all enrolled members
    member_emails = cohort.enrollments.joins(:user).pluck('users.email')
    mail(to: member_emails, subject: @subject, template_name: 'weekly_digest')
  end

  def milestone_achieved(cohort, milestone, user = nil)
    @cohort = cohort
    @milestone = milestone
    @user = user
    @subject = "Milestone Achieved: #{milestone.title}"

    if user
      mail(to: user.email, subject: @subject, template_name: 'milestone_achieved_individual')
    else
      # Send to all cohort members
      member_emails = cohort.enrollments.joins(:user).pluck('users.email')
      mail(to: member_emails, subject: @subject, template_name: 'milestone_achieved')
    end
  end

  def mentor_digest(cohort, mentor, stats = {})
    @cohort = cohort
    @mentor = mentor
    @stats = stats
    @subject = "Mentor Digest: #{cohort.title}"

    mail(to: mentor.email, subject: @subject, template_name: 'mentor_digest')
  end

  def inactive_member_notification(cohort, user, days_inactive = 30)
    @cohort = cohort
    @user = user
    @days_inactive = days_inactive
    @subject = "We Miss You in #{cohort.title}"

    mail(to: user.email, subject: @subject, template_name: 'inactive_member_notification')
  end

  def cohort_certificate_issued(cohort, user, certificate)
    @cohort = cohort
    @user = user
    @certificate = certificate
    @subject = "Certificate Issued: #{cohort.title}"

    mail(to: user.email, subject: @subject, template_name: 'cohort_certificate_issued')
  end

  def subgroup_created(cohort, subgroup)
    @cohort = cohort
    @subgroup = subgroup
    @subject = "New Subgroup Created: #{subgroup.title}"

    # Send to cohort staff and instructors
    recipient_emails = get_recipient_emails(cohort)
    mail(to: recipient_emails, subject: @subject, template_name: 'subgroup_created')
  end

  def cohort_statistics(cohort, stats)
    @cohort = cohort
    @stats = stats
    @subject = "Cohort Statistics: #{cohort.title}"

    # Send to cohort staff and instructors
    recipient_emails = get_recipient_emails(cohort)
    mail(to: recipient_emails, subject: @subject, template_name: 'cohort_statistics')
  end

  private

  def get_interested_users(cohort)
    # Get users who might be interested in this cohort
    # Based on course preferences, past enrollments, etc.
    User.joins(:enrollments)
       .where(enrollments: { course: cohort.course })
       .where.not(id: cohort.enrollments.select(:user_id))
       .distinct
  end

  def get_recipient_emails(cohort, subgroup = nil)
    emails = []

    # Add cohort instructor
    emails << cohort.instructor.email if cohort.instructor

    # Add cohort staff
    emails += cohort.cohort_staffs.joins(:user).pluck('users.email')

    # Add cohort mentors
    emails += cohort.mentors.pluck(:email)

    # Add subgroup mentors if specified
    if subgroup
      emails += subgroup.mentors.pluck(:email)
    end

    emails.compact.uniq
  end
end
