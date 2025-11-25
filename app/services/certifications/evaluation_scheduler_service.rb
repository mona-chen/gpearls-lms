module Certifications
  class EvaluationSchedulerService
    def self.schedule_evaluation(certificate_request, evaluator = nil)
      return { error: "Certificate request not found" } unless certificate_request

      # Find available evaluator if not specified
      evaluator ||= find_available_evaluator(certificate_request.course)

      return { error: "No available evaluator found" } unless evaluator

      # Schedule evaluation (next available slot)
      evaluation_date = find_next_available_slot(evaluator)

      certificate_request.update!(
        evaluator: evaluator,
        date: evaluation_date[:date],
        start_time: evaluation_date[:start_time],
        end_time: evaluation_date[:end_time],
        status: "Upcoming"
      )

      # Send notification to evaluator
      notify_evaluator(certificate_request)

      # Send confirmation to student
      notify_student(certificate_request)

      { success: true, evaluation: certificate_request }
    end

    def self.cancel_evaluation(certificate_request, reason = nil)
      return { error: "Certificate request not found" } unless certificate_request

      certificate_request.update!(
        status: "Cancelled",
        cancellation_reason: reason,
        cancelled_at: Time.current
      )

      # Send cancellation notifications
      notify_cancellation(certificate_request)

      { success: true, evaluation: certificate_request }
    end

    def self.reschedule_evaluation(certificate_request, new_date, new_start_time, new_end_time)
      return { error: "Certificate request not found" } unless certificate_request

      # Check if new slot is available
      unless slot_available?(certificate_request.evaluator, new_date, new_start_time, new_end_time, certificate_request.id)
        return { error: "Requested time slot is not available" }
      end

      certificate_request.update!(
        date: new_date,
        start_time: new_start_time,
        end_time: new_end_time
      )

      # Send rescheduling notifications
      notify_reschedule(certificate_request)

      { success: true, evaluation: certificate_request }
    end

    def self.complete_evaluation(certificate_request, evaluation_data)
      return { error: "Certificate request not found" } unless certificate_request

      # Update evaluation results
      certificate_request.update!(
        status: "Completed",
        rating: evaluation_data[:rating],
        summary: evaluation_data[:summary],
        completed_at: Time.current
      )

      # Create certificate if evaluation passed
      if evaluation_data[:rating] && evaluation_data[:rating] >= 3.0 # Assuming 3.0+ is passing
        create_certificate(certificate_request, evaluation_data)
      end

      # Send completion notifications
      notify_evaluation_complete(certificate_request)

      { success: true, evaluation: certificate_request }
    end

    private

    def self.find_available_evaluator(course)
      # Find evaluators for this course or general evaluators
      course_evaluators = course.evaluators.active.available_now
      return course_evaluators.first if course_evaluators.any?

      # Fallback to general evaluators
      User.evaluators.active.available_now.first
    end

    def self.find_next_available_slot(evaluator)
      # Find next available evaluation slot for the evaluator
      # This is a simplified implementation - in reality, you'd check their schedule

      tomorrow = Date.tomorrow
      start_time = Time.parse("10:00") # 10 AM
      end_time = Time.parse("11:00")   # 1 hour evaluation

      # Check if slot is available (simplified - no conflicts checked)
      {
        date: tomorrow,
        start_time: start_time,
        end_time: end_time
      }
    end

    def self.slot_available?(evaluator, date, start_time, end_time, exclude_evaluation_id = nil)
      # Check if the evaluator has any conflicting evaluations
      conflicts = CertificateRequest.where(evaluator: evaluator, date: date)
                                   .where.not(id: exclude_evaluation_id)
                                   .where("start_time < ? AND end_time > ?", end_time, start_time)

      conflicts.empty?
    end

    def self.notify_evaluator(certificate_request)
      # Send email/SMS notification to evaluator
      CertificateMailer.evaluation_scheduled(certificate_request).deliver_later
    end

    def self.notify_student(certificate_request)
      # Send confirmation to student
      CertificateMailer.evaluation_confirmed(certificate_request).deliver_later
    end

    def self.notify_cancellation(certificate_request)
      CertificateMailer.evaluation_cancelled(certificate_request).deliver_later
    end

    def self.notify_reschedule(certificate_request)
      CertificateMailer.evaluation_rescheduled(certificate_request).deliver_later
    end

    def self.notify_evaluation_complete(certificate_request)
      CertificateMailer.evaluation_completed(certificate_request).deliver_later
    end

    def self.create_certificate(certificate_request, evaluation_data)
      # Create the actual certificate
      certificate = Certificate.create!(
        user: certificate_request.user,
        course: certificate_request.course,
        evaluator: certificate_request.evaluator,
        issue_date: Date.current,
        expiry_date: 2.years.from_now, # Certificates valid for 2 years
        status: "Approved",
        evaluation_score: evaluation_data[:rating],
        evaluation_feedback: evaluation_data[:summary]
      )

      certificate
    end
  end
end