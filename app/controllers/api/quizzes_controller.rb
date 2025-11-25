class Api::QuizzesController < Api::BaseController
  skip_before_action :authenticate_user!, only: [ :index, :show ]

  def index
    quizzes = LmsQuiz.all
    render json: quizzes.map { |quiz| format_quiz(quiz) }
  end

  def create
    quiz_params = params.require(:quiz).permit(:title, :course_id, :passing_score, :time_limit, questions_attributes: [ :question, :question_type, :options, :correct_answer, :explanation ])

    quiz = LmsQuiz.create!(
      name: "quiz-#{Time.current.to_i}",
      title: quiz_params[:title],
      description: quiz_params[:title],
      course_id: quiz_params[:course_id],

      passing_percentage: quiz_params[:passing_score] || 70,
      duration_minutes: quiz_params[:time_limit] || 30,
      max_attempts: 3
    )

    # if quiz_params[:questions_attributes]
    #   quiz_params[:questions_attributes].each do |question_attrs|
    #     question = LmsQuestion.create!(
    #       question: question_attrs[:question],
    #       type: question_attrs[:question_type] == 'multiple_choice' ? 'Choices' : 'Text',
    #       option_1: question_attrs[:options][0],
    #       option_2: question_attrs[:options][1],
    #       option_3: question_attrs[:options][2],
    #       option_4: question_attrs[:options][3]
    #     )
    #     LmsQuizQuestion.create!(
    #       lms_quiz: quiz,
    #       lms_question: question,
    #       marks: 1
    #     )
    #   end
    # end

    render json: { id: quiz.id, title: quiz.title }, status: :created
  end

  def show
    quiz = LmsQuiz.find(params[:id])
    return render json: { error: "Quiz not found" }, status: :not_found unless quiz

    render json: quiz.to_frappe_format
  end

  def get_quiz_details
    quiz = LmsQuiz.find(params[:quiz_id] || params[:id])
    return render json: { error: "Quiz not found" }, status: :not_found unless quiz

    quiz_data = {
      name: quiz.id,
      title: quiz.title,
      description: quiz.description,
      passing_percentage: quiz.passing_percentage,
      total_marks: quiz.total_marks,
      duration: quiz.duration,
      show_answers: quiz.show_answers?,
      show_submission_history: quiz.show_submission_history?,
      shuffle_questions: quiz.shuffle_questions?,
      enable_negative_marking: quiz.enable_negative_marking?,
      marks_to_cut: quiz.marks_to_cut,
      questions: quiz.lms_quiz_questions.includes(:lms_question).map do |qq|
        question = qq.lms_question
        {
          name: qq.id,
          question: question.question,
          type: question.type,
          multiple: question.multiple_correct_answers?,
          marks: qq.marks,
          option_1: question.option_1,
          option_2: question.option_2,
          option_3: question.option_3,
          option_4: question.option_4,
          explanation_1: question.explanation_for_option(question.option_1),
          explanation_2: question.explanation_for_option(question.option_2),
          explanation_3: question.explanation_for_option(question.option_3),
          explanation_4: question.explanation_for_option(question.option_4)
        }
      end
    }

    render json: quiz_data
  end

  def submit
    quiz = LmsQuiz.find(params[:quiz_id] || params[:id])
    return render json: { error: "Quiz not found" }, status: :not_found unless quiz

    # Check if user has already submitted and quiz doesn't allow multiple attempts
    existing_submission = LmsQuizSubmission.find_by(quiz: quiz, member: current_user)
    if existing_submission && quiz.max_attempts && quiz.max_attempts > 0
      attempt_count = LmsQuizSubmission.where(quiz: quiz, member: current_user).count
      if attempt_count >= quiz.max_attempts
        return render json: { error: "Maximum attempts reached" }, status: :conflict
      end
    end

    # Process answers and calculate score
    total_marks = 0
    obtained_marks = 0
    answers_data = {}

    if params[:answers]
      params[:answers].each do |question_id, answer|
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
    end

    percentage = total_marks > 0 ? (obtained_marks.to_f / total_marks * 100).round(2) : 0

    # Create submission
    submission = LmsQuizSubmission.create!(
      quiz: quiz,
      member: current_user,
      course: quiz.course,
      score: obtained_marks,
      percentage: percentage,
      answers: answers_data,
      started_at: params[:started_at] ? Time.parse(params[:started_at]) : Time.current,
      completed_at: Time.current
    )

    render json: {
      name: submission.id,
      creation: submission.created_at.strftime("%Y-%m-%d %H:%M:%S"),
      score: obtained_marks,
      percentage: percentage,
      status: submission.passed? ? "Pass" : "Fail",
      passing_percentage: quiz.passing_percentage,
      result: submission.passed? ? "Pass" : "Fail",
      answers: answers_data
    }
  end

  def get_quiz_attempts
    quiz = LmsQuiz.find(params[:quiz_id] || params[:id])
    return render json: { error: "Quiz not found" }, status: :not_found unless quiz

    attempts = LmsQuizSubmission.where(quiz: quiz, member: current_user)
                               .order(created_at: :desc)
                               .map do |attempt|
      {
        name: attempt.id,
        creation: attempt.created_at.strftime("%Y-%m-%d %H:%M:%S"),
        score: attempt.score,
        percentage: attempt.percentage,
        status: attempt.passed? ? "Pass" : "Fail",
        result: attempt.passed? ? "Pass" : "Fail",
        time_taken: attempt.time_taken,
        started_at: attempt.started_at&.strftime("%Y-%m-%d %H:%M:%S"),
        completed_at: attempt.completed_at&.strftime("%Y-%m-%d %H:%M:%S")
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
      duration: quiz.duration,
      course: quiz.course&.id,
      lesson: quiz.lesson&.name
    }
  end

  def check_answer(question, answer)
    case question.type
    when "Choices"
      # Check if the answer matches any of the correct options
      correct_options = question.correct_options
      correct_options.include?(answer)
    when "User Input"
      # For user input, check against possible answers
      possible_answers = question.possible_answers
      possible_answers.any? { |possible| possible.downcase.strip == answer.downcase.strip }
    when "Open Ended"
      # Open ended questions require manual grading
      false
    else
      false
    end
  end
end
