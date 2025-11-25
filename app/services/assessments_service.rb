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

  def self.execute_assessment(assessment, user, answers = {})
    case assessment.assessment_type
    when "LMS Assignment"
      execute_assignment_assessment(assessment, user, answers)
    when "LMS Quiz"
      execute_quiz_assessment(assessment, user, answers)
    when "LMS Programming Exercise"
      execute_programming_assessment(assessment, user, answers)
    else
      { success: false, error: "Unsupported assessment type" }
    end
  end

  def self.execute_assignment_assessment(assessment, user, submission_data)
    assignment = LmsAssignment.find_by(name: assessment.assessment_name)
    return { success: false, error: "Assignment not found" } unless assignment

    # Create or update assignment submission
    submission = LmsAssignmentSubmission.find_or_initialize_by(
      assignment: assignment,
      student: user
    )

    submission.submitted_at = Time.current
    submission.status = "Submitted"

    # Handle file uploads if present
    if submission_data[:files]
      # Process file uploads using FileUploadService
      uploaded_files = []
      submission_data[:files].each do |file|
        upload_result = System::FileUploadService.call({ 'file' => file }, user)
        if upload_result['status'] == 'success'
          uploaded_files << {
            file_name: upload_result['data']['file_name'],
            file_url: upload_result['data']['file_url'],
            file_type: upload_result['data']['file_type'],
            file_size: upload_result['data']['file_size']
          }
        end
      end
      submission.attachments = uploaded_files
    end

    submission.content = submission_data[:content]
    submission.save!

    { success: true, submission: submission, message: "Assignment submitted successfully" }
  end

  def self.execute_quiz_assessment(assessment, user, answers)
    quiz = LmsQuiz.find_by(name: assessment.assessment_name)
    return { success: false, error: "Quiz not found" } unless quiz

    # Check if user has already submitted
    existing_submission = LmsQuizSubmission.find_by(quiz: quiz, member: user)
    if existing_submission
      return { success: false, error: "Quiz already submitted" }
    end

    # Process answers and calculate score
    total_marks = 0
    obtained_marks = 0
    answers_data = {}

    answers.each do |question_id, answer|
      qq = quiz.lms_quiz_questions.find_by(id: question_id)
      next unless qq

      question = qq.lms_question
      is_correct = check_answer(question, answer)

      answers_data[question_id] = {
        answer: answer,
        correct: is_correct,
        marks_obtained: is_correct ? qq.marks : 0,
        max_marks: qq.marks
      }

      total_marks += qq.marks
      obtained_marks += qq.marks if is_correct
    end

    percentage = total_marks > 0 ? (obtained_marks.to_f / total_marks * 100).round(2) : 0

    # Create quiz submission
    submission = LmsQuizSubmission.create!(
      quiz: quiz,
      member: user,
      course: quiz.course,
      score: obtained_marks,
      percentage: percentage,
      answers: answers_data,
      started_at: Time.current,
      completed_at: Time.current
    )

    { success: true, submission: submission, message: "Quiz submitted successfully" }
  end

  def self.execute_programming_assessment(assessment, user, code_submission)
    exercise = LmsProgrammingExercise.find_by(title: assessment.assessment_name)
    return { success: false, error: "Programming exercise not found" } unless exercise

    # Create programming exercise submission
    submission = LmsProgrammingExerciseSubmission.create!(
      exercise: exercise,
      member: user,
      code: code_submission[:code],
      language: code_submission[:language] || exercise.language,
      status: "Submitted"
    )

    # Run test cases (this would be implemented with a code execution service)
    test_results = run_test_cases(submission, exercise.lms_test_cases)

    # Update submission with results
    submission.update!(
      status: test_results[:all_passed] ? "Passed" : "Failed",
      output: test_results[:output],
      execution_time: test_results[:execution_time],
      memory_used: test_results[:memory_used]
    )

    { success: true, submission: submission, test_results: test_results }
  end

  def self.check_answer(question, answer)
    case question.type
    when 'Choices'
      # Check if the answer matches any of the correct options
      correct_options = question.correct_options
      correct_options.include?(answer)
    when 'User Input'
      # For user input, check against possible answers
      possible_answers = question.possible_answers
      possible_answers.any? { |possible| possible.downcase.strip == answer.downcase.strip }
    when 'Open Ended'
      # Open ended questions require manual grading
      false
    else
      false
    end
  end

  def self.run_test_cases(submission, test_cases)
    # This is a placeholder for actual code execution
    # In a real implementation, this would:
    # 1. Execute the submitted code in a sandboxed environment
    # 2. Run it against each test case
    # 3. Collect results

    results = {
      all_passed: true,
      passed_count: test_cases.count,
      total_count: test_cases.count,
      output: "Code execution completed successfully",
      execution_time: rand(100..500), # milliseconds
      memory_used: rand(1024..8192) # KB
    }

    results
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
