module Certifications
  class CertificateService
    def self.create_certificate(params, user)
      new(params, user).create
    end

    def initialize(params, user)
      @params = params
      @user = user
    end

    def create
      # Validate required parameters
      return error_response("User not found") unless @user
      return error_response("Course is required") unless @params[:course]

      course = Course.find_by(id: @params[:course])
      return error_response("Course not found") unless course

      # Check if user has completed the course
      enrollment = Enrollment.find_by(user: @user, course: course)
      return error_response("User is not enrolled in this course") unless enrollment
      return error_response("Course not completed") unless enrollment.completed?

      # Check if certificate already exists
      existing_certificate = Certificate.find_by(user: @user, course: course)
      if existing_certificate
        return success_response(existing_certificate, "Certificate already exists")
      end

      # Create certificate
      certificate = Certificate.new(
        user: @user,
        course: course,
        name: generate_certificate_name(@user, course),
        category: @params[:category] || "Course Completion",
        template: @params[:template] || "default",
        issued_date: Time.current,
        expiry_date: @params[:expiry_date] ? Date.parse(@params[:expiry_date]) : 1.year.from_now.to_date,
        published: @params[:published].nil? ? true : @params[:published]
      )

      if certificate.save
        success_response(certificate, "Certificate created successfully")
      else
        error_response(certificate.errors.full_messages.join(", "))
      end
    rescue ActiveRecord::RecordInvalid => e
      error_response(e.message)
    end

    def self.save_certificate_details(params, user)
      return error_response("User not authenticated") unless user
      return error_response("Certificate ID is required") unless params[:certificate_id]

      certificate = Certificate.find_by(id: params[:certificate_id])
      return error_response("Certificate not found") unless certificate

      # Check permissions - user must be the certificate owner or an admin
      unless certificate.user == user || user.admin?
        return error_response("Permission denied")
      end

      # Update certificate details
      update_attrs = {}
      update_attrs[:name] = params[:name] if params[:name].present?
      update_attrs[:category] = params[:category] if params[:category].present?
      update_attrs[:template] = params[:template] if params[:template].present?
      update_attrs[:expiry_date] = params[:expiry_date] ? Date.parse(params[:expiry_date]) : nil if params[:expiry_date].present?
      update_attrs[:published] = params[:published] unless params[:published].nil?

      if certificate.update(update_attrs)
        success_response(certificate, "Certificate details updated successfully")
      else
        error_response(certificate.errors.full_messages.join(", "))
      end
    rescue => e
      error_response("Failed to update certificate details: #{e.message}")
    end

    def self.create_lms_certificate(params, user)
      # This is an alias for create_certificate to match Frappe naming
      create_certificate(params, user)
    end

    def self.cancel_evaluation(params, user)
      return error_response("User not authenticated") unless user
      return error_response("Certificate ID is required") unless params[:certificate_id]

      certificate = Certificate.find_by(id: params[:certificate_id])
      return error_response("Certificate not found") unless certificate

      # Check permissions - user must be the certificate owner, evaluator, or an admin
      unless certificate.user == user || certificate.evaluator == user || user.admin?
        return error_response("Permission denied")
      end

      # Only allow cancellation if certificate is in pending/review status
      unless certificate.status.in?([ "Under Review", "Submitted", "Pending" ])
        return error_response("Certificate cannot be cancelled in its current status")
      end

      if certificate.update(status: "Cancelled", cancelled_at: Time.current, cancelled_by: user)
        success_response(certificate, "Certificate evaluation cancelled successfully")
      else
        error_response(certificate.errors.full_messages.join(", "))
      end
    rescue => e
      error_response("Failed to cancel certificate evaluation: #{e.message}")
    end

    def self.save_evaluation_details(params, user)
      return error_response("User not authenticated") unless user
      return error_response("Certificate ID is required") unless params[:certificate_id]

      certificate = Certificate.find_by(id: params[:certificate_id])
      return error_response("Certificate not found") unless certificate

      # Check permissions - user must be an evaluator or admin
      unless certificate.evaluator == user || user.admin? || user.evaluator?
        return error_response("Permission denied - only evaluators can save evaluation details")
      end

      # Update evaluation details
      update_attrs = {}
      update_attrs[:status] = params[:status] if params[:status].present?
      update_attrs[:evaluation_score] = params[:evaluation_score] if params[:evaluation_score].present?
      update_attrs[:evaluation_feedback] = params[:evaluation_feedback] if params[:evaluation_feedback].present?
      update_attrs[:evaluator] = user if certificate.evaluator.nil?
      update_attrs[:evaluated_at] = Time.current if params[:status] == "Approved" || params[:status] == "Rejected"

      if certificate.update(update_attrs)
        success_response(certificate, "Certificate evaluation details saved successfully")
      else
        error_response(certificate.errors.full_messages.join(", "))
      end
    rescue => e
      error_response("Failed to save certificate evaluation details: #{e.message}")
    end

    private

    def generate_certificate_name(user, course)
      "#{user.full_name} - #{course.title} - #{Time.current.year}"
    end

    def success_response(data, message = "Success")
      {
        success: true,
        data: data,
        message: message
      }
    end

    def error_response(message)
      {
        success: false,
        error: message,
        message: message
      }
    end
  end
end
