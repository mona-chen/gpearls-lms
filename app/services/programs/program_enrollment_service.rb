module Programs
  class ProgramEnrollmentService
    def self.enroll_in_program(program_name, user)
      new(program_name, user).enroll
    end

    def initialize(program_name, user)
      @program_name = program_name
      @user = user
    end

    def enroll
      program = LmsProgram.find_by(name: @program_name) || LmsProgram.find_by(id: @program_name)
      return error_response("Program not found") unless program
      return error_response("User not found") unless @user

      # Check if program is published
      return error_response("Program is not published") unless program.published?

      # Check if user is already enrolled
      existing_membership = program.lms_program_members.find_by(user: @user)
      return success_response(existing_membership, "Already enrolled in this program") if existing_membership

      # Create program membership
      membership = program.lms_program_members.create!(
        user: @user,
        progress: 0.0,
        creation: Time.current,
        modified: Time.current
      )

      # Auto-enroll in all program courses
      enroll_in_program_courses(program, @user)

      success_response(membership, "Successfully enrolled in program")
    rescue ActiveRecord::RecordInvalid => e
      error_response(e.message)
    end

    private

    def enroll_in_program_courses(program, user)
      program.lms_program_courses.includes(:course).ordered.each do |program_course|
        course = program_course.course
        next unless course

        # Create enrollment if not already enrolled
        Enrollment.find_or_create_by!(
          user: user,
          course: course
        ) do |enrollment|
          enrollment.member_type = "Student"
          enrollment.role = "Member"
        end
      end
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
