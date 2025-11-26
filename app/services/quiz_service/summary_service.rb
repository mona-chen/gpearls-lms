# frozen_string_literal: true

module Quiz
  class SummaryService
    def self.get_summary(quiz_id, user)
      return { error: "User not authenticated" } unless user
      return { error: "Quiz not found" } unless quiz_id

      quiz = Quiz.find_by(id: quiz_id)
      return { error: "Quiz not found" } unless quiz

      # Check if user is enrolled in the course
      unless user.enrollments.exists?(course_id: quiz.course_id)
        return { error: "User not enrolled in this course" }
      end

      # Get user's submission
      submission = QuizSubmission.find_by(user: user, quiz: quiz)

      # Get quiz statistics
      quiz_stats = get_quiz_statistics(quiz)

      # Get question breakdown
      question_breakdown = get_question_breakdown(quiz, user)

      # Get user performance
      user_performance = get_user_performance(quiz, user, submission)

      {
        success: true,
        quiz: {
          id: quiz.id,
          title: quiz.title,
          description: quiz.description || "",
          total_questions: quiz.quiz_questions.count,
          total_points: quiz.quiz_questions.sum(:points),
          course_id: quiz.course_id,
          course_title: quiz.course&.title
        },
        user_submission: submission ? {
          id: submission.id,
          score: submission.score,
          max_score: submission.max_score,
          percentage: submission.max_score > 0 ? ((submission.score.to_f / submission.max_score) * 100).round(2) : 0,
          status: submission.status,
          submitted_at: submission.submitted_at&.strftime("%Y-%m-%d %H:%M:%S"),
          attempts: QuizSubmission.where(user: user, quiz: quiz).count
        } : nil,
        statistics: quiz_stats,
        question_breakdown: question_breakdown,
        user_performance: user_performance,
        recommendations: generate_recommendations(quiz, user, submission)
      }
    rescue => e
      {
        error: "Failed to get quiz summary",
        details: e.message
      }
    end

    def self.get_course_quiz_summary(course_id, user)
      return { error: "User not authenticated" } unless user

      course = Course.find_by(id: course_id)
      return { error: "Course not found" } unless course

      # Check enrollment
      unless user.enrollments.exists?(course_id: course_id)
        return { error: "User not enrolled in this course" }
      end

      quizzes = course.quizzes.includes(:quiz_questions, :quiz_submissions)

      quiz_summaries = quizzes.map do |quiz|
        user_submission = quiz.quiz_submissions.find_by(user: user)

        {
          id: quiz.id,
          title: quiz.title,
          total_questions: quiz.quiz_questions.count,
          total_points: quiz.quiz_questions.sum(:points),
          user_score: user_submission&.score || 0,
          max_score: user_submission&.max_score || quiz.quiz_questions.sum(:points),
          percentage: user_submission&.max_score ? ((user_submission.score.to_f / user_submission.max_score) * 100).round(2) : 0,
          status: user_submission&.status || "not_attempted",
          submitted_at: user_submission&.submitted_at&.strftime("%Y-%m-%d %H:%M:%S")
        }
      end

      total_quiz_points = quizzes.joins(:quiz_questions).sum("quiz_questions.points")
      total_user_score = quiz_summaries.sum { |q| q[:user_score] }
      overall_percentage = total_quiz_points > 0 ? ((total_user_score.to_f / total_quiz_points) * 100).round(2) : 0

      {
        success: true,
        course_id: course_id,
        course_title: course.title,
        total_quizzes: quizzes.count,
        attempted_quizzes: quiz_summaries.count { |q| q[:status] != "not_attempted" },
        completed_quizzes: quiz_summaries.count { |q| q[:status] == "completed" },
        total_quiz_points: total_quiz_points,
        total_user_score: total_user_score,
        overall_percentage: overall_percentage,
        quizzes: quiz_summaries
      }
    rescue => e
      {
        error: "Failed to get course quiz summary",
        details: e.message
      }
    end

    private

    def self.get_quiz_statistics(quiz)
      submissions = quiz.quiz_submissions

      {
        total_attempts: submissions.count,
        unique_participants: submissions.select(:user_id).distinct.count,
        average_score: submissions.exists? ? (submissions.average(:score) || 0).round(2) : 0,
        average_percentage: submissions.where.not(max_score: 0).exists? ?
          (submissions.average("score::float / max_score::float * 100") || 0).round(2) : 0,
        highest_score: submissions.maximum(:score) || 0,
        lowest_score: submissions.minimum(:score) || 0,
        completion_rate: submissions.where(status: "completed").count > 0 ?
          ((submissions.where(status: "completed").count.to_f / submissions.count) * 100).round(2) : 0
      }
    end

    def self.get_question_breakdown(quiz, user)
      quiz.quiz_questions.includes(:quiz_results).order(:order).map do |question|
        user_result = question.quiz_results.find_by(user: user)

        {
          question_id: question.id,
          question: question.question,
          type: question.type,
          points: question.points || 1,
          user_score: user_result&.score || 0,
          user_correct: user_result&.correct || false,
          correct_answer: question.correct_answer,
          explanation: question.explanation || "",
          difficulty: calculate_question_difficulty(question),
          success_rate: calculate_question_success_rate(question)
        }
      end
    end

    def self.get_user_performance(quiz, user, submission)
      return nil unless submission

      all_submissions = QuizSubmission.where(quiz: quiz)
      user_rank = all_submissions.order(score: :desc, submitted_at: :asc).pluck(:user_id).index(user.id) + 1

      {
        rank: user_rank,
        total_participants: all_submissions.count,
        percentile: user_rank && all_submissions.count > 0 ?
          (((all_submissions.count - user_rank + 1).to_f / all_submissions.count) * 100).round(2) : 0,
        improvement: calculate_improvement(quiz, user),
        time_spent: calculate_time_spent(submission)
      }
    end

    def self.generate_recommendations(quiz, user, submission)
      recommendations = []

      unless submission
        recommendations << "You haven't attempted this quiz yet. Take your time to review the course material before starting."
        return recommendations
      end

      percentage = submission.max_score > 0 ? ((submission.score.to_f / submission.max_score) * 100) : 0

      case percentage
      when 0..40
        recommendations << "Consider reviewing the course material thoroughly before retaking the quiz."
        recommendations << "Focus on understanding the fundamental concepts."
      when 41..70
        recommendations << "Good effort! Review the questions you got wrong to improve your understanding."
        recommendations << "Consider reviewing specific topics where you lost points."
      when 71..90
        recommendations << "Well done! You have a good understanding of the material."
        recommendations << "Review the remaining questions to achieve mastery."
      when 91..100
        recommendations << "Excellent work! You have mastered this topic."
        recommendations << "Consider helping others who might be struggling with this material."
      end

      # Add specific recommendations based on question types
      if submission.answers.present?
        answers_data = submission.answers.is_a?(String) ? JSON.parse(submission.answers) : submission.answers

        quiz.quiz_questions.each do |question|
          user_answer = answers_data[question.id.to_s] || answers_data[question.name.to_s]
          next unless user_answer

          answer_result = Quiz::AnswerService.check(question.id, user_answer)
          if answer_result[:success] && !answer_result[:result][:is_correct]
            recommendations << "Review: #{question.question}"
          end
        end
      end

      recommendations
    end

    def self.calculate_question_difficulty(question)
      submissions = question.quiz_results

      return "Medium" if submissions.empty?

      success_rate = submissions.where(correct: true).count.to_f / submissions.count

      case success_rate
      when 0..0.3
        "Hard"
      when 0.31..0.7
        "Medium"
      when 0.71..1.0
        "Easy"
      end
    end

    def self.calculate_question_success_rate(question)
      submissions = question.quiz_results

      return 0 if submissions.empty?

      ((submissions.where(correct: true).count.to_f / submissions.count) * 100).round(2)
    end

    def self.calculate_improvement(quiz, user)
      user_submissions = QuizSubmission.where(user: user, quiz: quiz).order(:submitted_at)

      return 0 if user_submissions.count <= 1

      first_score = user_submissions.first.score || 0
      last_score = user_submissions.last.score || 0

      last_score - first_score
    end

    def self.calculate_time_spent(submission)
      # This would require tracking start time
      # For now, return a placeholder
      "Not tracked"
    end
  end
end
