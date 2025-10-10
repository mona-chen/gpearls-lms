class Api::QuizzesController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:index]
  
  def index
    quizzes = Quiz.all
    render json: quizzes.map { |quiz| format_quiz(quiz) }
  end
  
  def get_quiz_details
    quiz = Quiz.find(params[:quiz_id])
    return render json: { error: 'Quiz not found' }, status: :not_found unless quiz

    quiz_data = {
      name: quiz.id,
      title: quiz.title,
      description: quiz.description,
      passing_percentage: quiz.passing_percentage,
      total_marks: quiz.total_marks,
      duration: quiz.duration,
      show_answers: quiz.show_answers,
      show_submission_history: quiz.show_submission_history,
      questions: quiz.quiz_questions.order(:position).map do |q|
        {
          name: q.id,
          question: q.question,
          type: q.type,
          multiple: q.multiple,
          marks: q.marks,
          option_1: q.option_1,
          option_2: q.option_2,
          option_3: q.option_3,
          option_4: q.option_4,
          explanation_1: q.explanation_1,
          explanation_2: q.explanation_2,
          explanation_3: q.explanation_3,
          explanation_4: q.explanation_4
        }
      end
    }

    render json: quiz_data
  end

  def submit
    quiz = Quiz.find(params[:quiz_id])
    return render json: { error: 'Quiz not found' }, status: :not_found unless quiz

    # Check if user has already submitted
    existing_submission = QuizSubmission.find_by(quiz: quiz, user: current_user)
    if existing_submission && !quiz.show_submission_history
      return render json: { error: 'Already submitted' }, status: :conflict
    end

    # Process answers
    results = []
    total_marks = 0
    obtained_marks = 0

    if params[:answers]
      params[:answers].each do |question_id, answer|
        question = quiz.quiz_questions.find(question_id)
        is_correct = check_answer(question, answer)

        results << {
          question_name: question.question,
          answer: answer,
          is_correct: is_correct,
          marks_obtained: is_correct ? question.marks : 0,
          marks_out_of: question.marks
        }

        total_marks += question.marks
        obtained_marks += question.marks if is_correct
      end
    end

    percentage = total_marks > 0 ? (obtained_marks.to_f / total_marks * 100).round(2) : 0

    # Create submission
    submission = QuizSubmission.create!(
      quiz: quiz,
      user: current_user,
      course: quiz.course,
      score: obtained_marks,
      percentage: percentage,
      quiz_title: quiz.title,
      total_marks: total_marks,
      quiz_results_attributes: results
    )

    render json: {
      name: submission.id,
      creation: submission.created_at,
      score: obtained_marks,
      percentage: percentage,
      status: percentage >= quiz.passing_percentage ? 'Pass' : 'Fail',
      passing_percentage: quiz.passing_percentage,
      results: results
    }
  end

  def get_quiz_attempts
    quiz = Quiz.find(params[:quiz_id])
    return render json: { error: 'Quiz not found' }, status: :not_found unless quiz

    attempts = QuizSubmission.where(quiz: quiz, user: current_user)
                             .order(created_at: :desc)
                             .map do |attempt|
      {
        name: attempt.id,
        creation: attempt.created_at,
        score: attempt.score,
        percentage: attempt.percentage,
        status: attempt.status,
        total_marks: attempt.total_marks
      }
    end

    render json: attempts
  end

  private

  def format_quiz(quiz)
    {
      name: quiz.id,
      title: quiz.title,
      description: quiz.description,
      passing_percentage: quiz.passing_percentage,
      total_marks: quiz.total_marks,
      duration: 60, # Default duration in minutes
      course: quiz.course&.id
    }
  end

  def check_answer(question, answer)
    case question.type
    when 'Choices'
      correct_option = [1, 2, 3, 4].find { |i| question.send("option_#{i}") == question.send("explanation_#{i}")&.gsub(/^\d+\.\s*/, '') }
      answer.to_i == correct_option
    when 'True-False'
      answer.downcase == question.option_1.downcase
    else
      false
    end
  end
end