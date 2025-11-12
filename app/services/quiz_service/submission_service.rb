# frozen_string_literal: true

module QuizService
  class SubmissionService
    def self.submit(exercise_id, code, user)
      return { error: "User not authenticated" } unless user
      return { error: "Exercise/Quiz not found" } unless exercise_id

      # Try to find quiz first, then exercise
      quiz = Quiz.find_by(id: exercise_id)
      exercise = Exercise.find_by(id: exercise_id) if quiz.nil?

      return { error: "Quiz or Exercise not found" } unless quiz || exercise

      if quiz
        submit_quiz_submission(quiz, code, user)
      elsif exercise
        submit_exercise_submission(exercise, code, user)
      end
    rescue => e
      {
        error: "Failed to submit solution",
        details: e.message
      }
    end

    def self.submit_quiz_submission(quiz, answers, user)
      # Check if user is enrolled in the course
      unless user.enrollments.exists?(course_id: quiz.course_id)
        return { error: "User not enrolled in this course" }
      end

      # Create or update submission
      submission = QuizSubmission.find_or_initialize_by(
        user: user,
        quiz: quiz
      )

      # Parse answers if it's a JSON string
      answers_data = answers.is_a?(String) ? JSON.parse(answers || "{}") : (answers || {})

      # Calculate score
      total_score = 0
      max_score = 0
      results = []

      quiz.quiz_questions.each do |question|
        user_answer = answers_data[question.id.to_s] || answers_data[question.name.to_s]
        max_score += question.points || 1

        answer_result = Quiz::AnswerService.check(question.id, user_answer)
        if answer_result[:success]
          total_score += answer_result[:result][:score]
          results << answer_result[:result]
        else
          results << {
            question_id: question.id,
            question: question.question,
            user_answer: user_answer,
            error: "Failed to check answer"
          }
        end
      end

      # Update submission
      submission.update!(
        answers: answers_data,
        score: total_score,
        max_score: max_score,
        status: total_score >= max_score ? "completed" : "submitted",
        submitted_at: Time.current
      )

      # Update course progress
      update_course_progress(user, quiz.course)

      {
        success: true,
        submission_id: submission.id,
        score: total_score,
        max_score: max_score,
        percentage: max_score > 0 ? ((total_score.to_f / max_score) * 100).round(2) : 0,
        status: submission.status,
        results: results,
        submitted_at: submission.submitted_at.strftime("%Y-%m-%d %H:%M:%S"),
        message: "Quiz submitted successfully"
      }
    end

    def self.submit_exercise_submission(exercise, code, user)
      # Check if user is enrolled in the course
      unless user.enrollments.exists?(course_id: exercise.course_id)
        return { error: "User not enrolled in this course" }
      end

      # Create submission
      submission = ExerciseSubmission.create!(
        user: user,
        exercise: exercise,
        code: code,
        status: "submitted",
        submitted_at: Time.current
      )

      # For programming exercises, you might want to run tests here
      # For now, we'll just mark as submitted
      test_results = run_code_tests(exercise, code) if exercise.test_cases.present?

      if test_results
        submission.update!(
          test_results: test_results,
          score: test_results[:score],
          max_score: test_results[:max_score],
          status: test_results[:passed] ? "completed" : "failed"
        )
      end

      {
        success: true,
        submission_id: submission.id,
        status: submission.status,
        score: submission.score,
        max_score: submission.max_score,
        test_results: test_results,
        submitted_at: submission.submitted_at.strftime("%Y-%m-%d %H:%M:%S"),
        message: "Exercise submitted successfully"
      }
    end

    def self.get_submission_history(user, quiz_id = nil)
      return { error: "User not authenticated" } unless user

      submissions = QuizSubmission.includes(:quiz, :user)
                                  .where(user: user)
      submissions = submissions.where(quiz_id: quiz_id) if quiz_id

      submissions_data = submissions.map do |submission|
        {
          id: submission.id,
          quiz_id: submission.quiz_id,
          quiz_title: submission.quiz&.title,
          score: submission.score,
          max_score: submission.max_score,
          percentage: submission.max_score > 0 ? ((submission.score.to_f / submission.max_score) * 100).round(2) : 0,
          status: submission.status,
          submitted_at: submission.submitted_at&.strftime("%Y-%m-%d %H:%M:%S"),
          created_at: submission.created_at&.strftime("%Y-%m-%d %H:%M:%S")
        }
      end

      {
        success: true,
        submissions: submissions_data,
        total_submissions: submissions_data.count,
        average_score: submissions_data.empty? ? 0 : (submissions_data.sum { |s| s[:percentage] } / submissions_data.count).round(2)
      }
    end

    private

    def self.update_course_progress(user, course)
      return unless course

      total_lessons = course.lessons.count
      total_quizzes = course.quizzes.count
      total_activities = total_lessons + total_quizzes
      return if total_activities == 0

      completed_lessons = user.lesson_progresses
                               .joins(:lesson)
                               .where(lessons: { course: course.id.to_s }, completed: true)
                               .count

      completed_quizzes = user.quiz_submissions
                              .where(quiz: course.quizzes, status: "completed")
                              .count

      completed_activities = completed_lessons + completed_quizzes
      new_progress = (completed_activities.to_f / total_activities * 100).round(2)

      course_progress = user.course_progresses.where(course: course).first_or_create
      course_progress.update!(
        progress: new_progress,
        status: new_progress >= 80 ? "Completed" : "In Progress",
        updated_at: Time.current
      )
    end

    def self.run_code_tests(exercise, code)
      # This is a placeholder for code testing logic
      # In a real implementation, you would:
      # 1. Set up a sandbox environment
      # 2. Run the user's code against test cases
      # 3. Return test results

      {
        passed: true,
        score: 10,
        max_score: 10,
        test_cases: [
          { name: "Test Case 1", passed: true, output: "Expected output" },
          { name: "Test Case 2", passed: true, output: "Expected output" }
        ],
        execution_time: "0.5s",
        memory_usage: "10MB"
      }
    end
  end
end
