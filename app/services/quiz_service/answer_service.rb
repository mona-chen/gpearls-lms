# frozen_string_literal: true

module QuizService
  class AnswerService
    def self.check(question_id, user_answer)
      question = QuizQuestion.find_by(id: question_id)
      return { error: "Question not found" } unless question

      # Parse options if needed
      options = question.options.is_a?(String) ? JSON.parse(question.options || "[]") : (question.options || [])

      # Check answer correctness
      is_correct = check_answer_correctness(question, user_answer, options)

      # Calculate score
      score = is_correct ? (question.points || 1) : 0

      result = {
        question_id: question.id,
        question: question.question,
        user_answer: user_answer,
        correct_answer: question.correct_answer,
        is_correct: is_correct,
        score: score,
        max_score: question.points || 1,
        explanation: question.explanation || "",
        question_type: question.type
      }

      # Add feedback for different question types
      case question.type&.downcase
      when "multiple choice", "single choice"
        result[:feedback] = generate_multiple_choice_feedback(question, user_answer, is_correct, options)
      when "true/false"
        result[:feedback] = generate_true_false_feedback(question, user_answer, is_correct)
      when "short answer"
        result[:feedback] = generate_short_answer_feedback(question, user_answer, is_correct)
      else
        result[:feedback] = is_correct ? "Correct!" : "Incorrect. Please try again."
      end

      {
        success: true,
        result: result
      }
    rescue => e
      {
        error: "Failed to check answer",
        details: e.message
      }
    end

    private

    def self.check_answer_correctness(question, user_answer, options)
      case question.type&.downcase
      when "multiple choice"
        # For multiple choice, user_answer should be an array
        user_answers = Array(user_answer)
        correct_answers = Array(question.correct_answer)
        (user_answers.sort == correct_answers.sort)
      when "single choice"
        user_answer.to_s == question.correct_answer.to_s
      when "true/false"
        user_answer.to_s.downcase == question.correct_answer.to_s.downcase
      when "short answer"
        # Case-insensitive comparison for short answers
        user_answer.to_s.strip.downcase == question.correct_answer.to_s.strip.downcase
      when "numeric"
        # Allow for small floating point differences
        user_answer.to_f.abs - question.correct_answer.to_f.abs < 0.01
      else
        user_answer.to_s == question.correct_answer.to_s
      end
    end

    def self.generate_multiple_choice_feedback(question, user_answer, is_correct, options)
      if is_correct
        "Correct! Well done."
      else
        correct_option = options.find { |opt| opt["value"] == question.correct_answer }
        if correct_option
          "Incorrect. The correct answer is: #{correct_option['label'] || correct_option['value']}"
        else
          "Incorrect. Please review the question and try again."
        end
      end
    end

    def self.generate_true_false_feedback(question, user_answer, is_correct)
      if is_correct
        "Correct! That is the right answer."
      else
        "Incorrect. The correct answer is: #{question.correct_answer}"
      end
    end

    def self.generate_short_answer_feedback(question, user_answer, is_correct)
      if is_correct
        "Correct! Your answer matches exactly."
      else
        "Incorrect. Please check your spelling and try again."
      end
    end
  end
end
