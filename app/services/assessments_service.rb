class AssessmentsService
    def self.call(params, user = nil)
      batch = params[:batch]
      return [] unless batch

      get_assessments(batch, user&.email)
    end

    def self.get_assessments(batch, member = nil)
      # Default to current user if no member specified
      member ||= Current.user&.email
      return [] unless member

      user = User.find_by(email: member)
      return [] unless user

      # Get all assessments for the batch
      assessments = LmsAssessment.where(parent: batch)

      # Process each assessment based on type
      assessments.map do |assessment|
        case assessment.assessment_type
        when "LMS Assignment"
          get_assignment_details(assessment, user)
        when "LMS Quiz"
          get_quiz_details(assessment, user)
        when "LMS Programming Exercise"
          get_exercise_details(assessment, user)
        else
          assessment.to_frappe_format
        end
      end
    end

    private

    def self.get_assignment_details(assessment, user)
      assignment = LmsAssignment.find_by(name: assessment.assessment_name)
      return assessment.to_frappe_format unless assignment

      # Get user's submission status
      submission = LmsAssignmentSubmission.find_by(
        assignment_id: assignment.id,
        student_id: user.id
      )

      assessment_data = assessment.to_frappe_format.merge(
        title: assignment.title,
        description: assignment.description,
        type: "assignment",
        submitted: submission.present?,
        submission_date: submission&.submitted_at,
        graded: submission&.status == "Completed",
        score: submission&.marks_obtained,
        max_score: assignment.maximum_score
      )

      assessment_data
    end

    def self.get_quiz_details(assessment, user)
      quiz = LmsQuiz.find_by(name: assessment.assessment_name)
      return assessment.to_frappe_format unless quiz

      # Get user's quiz result
      quiz_result = LmsQuizResult.find_by(
        quiz_id: quiz.id,
        user_id: user.id
      )

      assessment_data = assessment.to_frappe_format.merge(
        title: quiz.title,
        description: quiz.description,
        type: "quiz",
        attempted: quiz_result.present?,
        score: quiz_result&.score,
        max_score: quiz_result&.max_score,
        percentage: quiz_result&.percentage,
        status: quiz_result&.status || "Not Attempted",
        passing_percentage: quiz.passing_percentage
      )

      assessment_data
    end

    def self.get_exercise_details(assessment, user)
      # For programming exercises - this would need the programming exercise model
      # For now, return basic assessment data
      assessment.to_frappe_format.merge(
        type: "programming_exercise",
        attempted: false # Would need to check submissions
      )
    end
end
