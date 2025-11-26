module BatchAndCohortNotificationsJob
  extend ActiveSupport::Concern

  included do
    # Class methods for scheduling
    def self.schedule_batch_start_reminders
      # Run daily at 9 AM
      cron("0 9 * * *") { BatchStartReminderJob.perform_later }
    end

    def self.schedule_cohort_notifications
      # Run daily at 10 AM
      cron("0 10 * * *") { CohortNotificationJob.perform_later }
    end

    def self.schedule_cleanup_tasks
      # Run weekly on Sunday at 2 AM
      cron("0 2 * * 0") { CleanupJob.perform_later }
    end
  end

  class BatchStartReminderJob < ApplicationJob
    queue_as :default

    def perform(*args)
      Rails.logger.info "Running batch start reminder job..."

      results = {
        batches_processed: 0,
        emails_sent: 0,
        errors: []
      }

      begin
        # Get batches starting tomorrow
        tomorrow = Date.current + 1.day
        batches = Batch.published.where(start_date: tomorrow)

        batches.find_each do |batch|
          results[:batches_processed] += 1

          batch.batch_enrollments.includes(:user).find_each do |enrollment|
            begin
              BatchEnrollmentMailer.start_reminder(enrollment).deliver_later
              results[:emails_sent] += 1
            rescue => e
              results[:errors] << "Failed to send reminder to #{enrollment.user.email}: #{e.message}"
              Rails.logger.error "Batch reminder error: #{e.message}"
            end
          end
        end

        Rails.logger.info "Batch start reminder job completed: #{results}"
        results
      rescue => e
        Rails.logger.error "Batch start reminder job failed: #{e.message}"
        { error: e.message, backtrace: e.backtrace }
      end
    end
  end

  class CohortNotificationJob < ApplicationJob
    queue_as :default

    def perform(*args)
      Rails.logger.info "Running cohort notification job..."

      results = {
        start_reminders_sent: 0,
        completion_notifications_sent: 0,
        emails_sent: 0,
        errors: []
      }

      begin
        # Send start reminders for cohorts starting tomorrow
        tomorrow = Date.current + 1.day
        starting_cohorts = Cohort.where(begin_date: tomorrow, status: "Upcoming")

        starting_cohorts.find_each do |cohort|
          results[:start_reminders_sent] += 1
          begin
            CohortMailer.cohort_started(cohort).deliver_later
            results[:emails_sent] += cohort.enrollments.count
          rescue => e
            results[:errors] << "Failed to send start notification for cohort #{cohort.title}: #{e.message}"
            Rails.logger.error "Cohort start notification error: #{e.message}"
          end
        end

        # Send completion notifications for cohorts that completed today
        today = Date.current
        completed_cohorts = Cohort.where(end_date: today, status: "Live")

        completed_cohorts.find_each do |cohort|
          results[:completion_notifications_sent] += 1
          begin
            CohortMailer.cohort_completed(cohort).deliver_later
            results[:emails_sent] += cohort.enrollments.count
          rescue => e
            results[:errors] << "Failed to send completion notification for cohort #{cohort.title}: #{e.message}"
            Rails.logger.error "Cohort completion notification error: #{e.message}"
          end
        end

        # Process pending join requests older than 30 days
        processed = Cohorts::CohortService.process_pending_join_requests(30)
        results.merge!(processed.symbolize_keys)

        Rails.logger.info "Cohort notification job completed: #{results}"
        results
      rescue => e
        Rails.logger.error "Cohort notification job failed: #{e.message}"
        { error: e.message, backtrace: e.backtrace }
      end
    end
  end

  class CleanupJob < ApplicationJob
    queue_as :low_priority

    def perform(*args)
      Rails.logger.info "Running cleanup job for batches and cohorts..."

      results = {
        old_join_requests_processed: 0,
        inactive_users_notified: 0,
        expired_drafts_cleaned: 0,
        errors: []
      }

      begin
        # Process old join requests
        processed = Cohorts::CohortService.process_pending_join_requests(30)
        results[:old_join_requests_processed] = processed[:processed_count]

        # Notify inactive cohort members (no activity for 90 days)
        inactive_cutoff = 90.days.ago
        inactive_enrollments = Enrollment.joins(:user)
                                  .joins("LEFT JOIN lesson_progresses ON lesson_progresses.user_id = users.id AND lesson_progresses.course_id = enrollments.course_id")
                                  .where("lesson_progresses.updated_at < ? OR lesson_progresses.updated_at IS NULL", inactive_cutoff)
                                  .where.not(cohort_id: nil)
                                  .limit(100)

        inactive_enrollments.find_each do |enrollment|
          results[:inactive_users_notified] += 1
          begin
            CohortMailer.inactive_member_notification(enrollment.cohort, enrollment.user, 90).deliver_later
          rescue => e
            results[:errors] << "Failed to notify inactive user #{enrollment.user.email}: #{e.message}"
            Rails.logger.error "Inactive user notification error: #{e.message}"
          end
        end

        # Clean up expired draft batches (older than 30 days)
        expired_cutoff = 30.days.ago
        expired_drafts = Batch.where(published: false, created_at: ...expired_cutoff)
                           .limit(50)

        expired_drafts.find_each do |batch|
          results[:expired_drafts_cleaned] += 1
          begin
            batch.destroy
          rescue => e
            results[:errors] << "Failed to delete expired draft batch #{batch.title}: #{e.message}"
            Rails.logger.error "Draft cleanup error: #{e.message}"
          end
        end

        Rails.logger.info "Cleanup job completed: #{results}"
        results
      rescue => e
        Rails.logger.error "Cleanup job failed: #{e.message}"
        { error: e.message, backtrace: e.backtrace }
      end
    end
  end

  class StatisticsJob < ApplicationJob
    queue_as :low_priority

    def perform(*args)
      Rails.logger.info "Running statistics job for batches and cohorts..."

      results = {
        batch_stats_generated: 0,
        cohort_stats_generated: 0,
        reports_sent: 0,
        errors: []
      }

      begin
        # Generate batch statistics
        Batch.active.find_each do |batch|
          results[:batch_stats_generated] += 1
          begin
            stats = Batches::BatchService.get_batch_statistics(batch)
            # Store statistics or send to admin
            generate_batch_report(batch, stats)
          rescue => e
            results[:errors] << "Failed to generate stats for batch #{batch.title}: #{e.message}"
            Rails.logger.error "Batch stats error: #{e.message}"
          end
        end

        # Generate cohort statistics
        Cohort.active.find_each do |cohort|
          results[:cohort_stats_generated] += 1
          begin
            stats = Cohorts::CohortService.get_cohort_statistics(cohort)
            # Store statistics or send to admin
            generate_cohort_report(cohort, stats)
          rescue => e
            results[:errors] << "Failed to generate stats for cohort #{cohort.title}: #{e.message}"
            Rails.logger.error "Cohort stats error: #{e.message}"
          end
        end

        # Send weekly reports to administrators
        send_weekly_reports
        results[:reports_sent] += 1

        Rails.logger.info "Statistics job completed: #{results}"
        results
      rescue => e
        Rails.logger.error "Statistics job failed: #{e.message}"
        { error: e.message, backtrace: e.backtrace }
      end
    end

    private

    def generate_batch_report(batch, stats)
      # Generate and store batch performance report
      # Could save to database or send to admin dashboard
      Rails.logger.info "Generated report for batch #{batch.title}: #{stats}"
    end

    def generate_cohort_report(cohort, stats)
      # Generate and store cohort performance report
      # Could save to database or send to admin dashboard
      Rails.logger.info "Generated report for cohort #{cohort.title}: #{stats}"
    end

    def send_weekly_reports
      # Send weekly summary reports to administrators
      admin_emails = User.where(is_admin: true).pluck(:email)

      admin_emails.each do |email|
        begin
          BatchMailer.weekly_digest.deliver_later
        rescue => e
          Rails.logger.error "Failed to send weekly digest to #{email}: #{e.message}"
        end
      end
    end
  end

  # Module methods for easy access
  module ClassMethods
    def run_batch_start_reminders
      BatchStartReminderJob.perform_now
    end

    def run_cohort_notifications
      CohortNotificationJob.perform_now
    end

    def run_cleanup_tasks
      CleanupJob.perform_now
    end

    def run_statistics_job
      StatisticsJob.perform_now
    end

    def schedule_all_jobs
      schedule_batch_start_reminders
      schedule_cohort_notifications
      schedule_cleanup_tasks
    end
  end

  extend ClassMethods
end
