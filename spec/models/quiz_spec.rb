require 'rails_helper'

RSpec.describe LmsQuiz, type: :model do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:quiz) do
    LmsQuiz.create!(
      name: 'test_quiz',
      title: 'Test Quiz',
      description: 'Test quiz description',
      course: course,
      max_attempts: 3,
      duration_minutes: 60,
      passing_percentage: 90.0,
      status: 'Draft',
      quiz_type: 'Graded',
      total_marks: 100.0
    )
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(quiz).to be_valid
    end

    it 'is invalid without a title' do
      quiz.title = nil
      expect(quiz).to_not be_valid
    end

    it 'is invalid with negative passing percentage' do
      quiz.passing_percentage = -1
      expect(quiz).to_not be_valid
    end

    it 'is invalid with passing percentage over 100' do
      quiz.passing_percentage = 101
      expect(quiz).to_not be_valid
    end
  end

  describe 'associations' do
    it 'belongs to course' do
      expect(quiz).to respond_to(:course)
    end

    it 'has many lms_questions' do
      expect(quiz).to respond_to(:lms_questions)
    end

    it 'has many quiz_submissions' do
      expect(quiz).to respond_to(:quiz_submissions)
    end
  end

  describe 'questions' do
    let!(:question1) { create(:lms_question, quiz: quiz, question: 'Question 1', question_type: 'Choices') }
    let!(:question2) { create(:lms_question, quiz: quiz, question: 'Question 2', question_type: 'User Input') }

    it 'has correct question count' do
      expect(quiz.lms_questions.count).to eq(2)
    end

    it 'validates question types' do
      expect(question1.question_type).to eq('Choices')
      expect(question2.question_type).to eq('User Input')
    end
  end

  describe '#total_marks' do
    let!(:question1) { create(:lms_question, quiz: quiz, marks: 10) }
    let!(:question2) { create(:lms_question, quiz: quiz, marks: 15) }

    it 'calculates total marks correctly' do
      expect(quiz.total_marks).to eq(25)
    end
  end

  describe '#passing_marks' do
    let!(:question1) { create(:lms_question, quiz: quiz, marks: 10) }
    let!(:question2) { create(:lms_question, quiz: quiz, marks: 15) }

    it 'calculates passing marks correctly' do
      # Total marks = 25, passing percentage = 90%
      expect(quiz.passing_marks).to eq(22.5)
    end
  end

  describe '#user_attempts' do
    let(:user) { create(:user) }

    it 'returns 0 when user has no attempts' do
      expect(quiz.user_attempts(user)).to eq(0)
    end

    it 'returns correct attempt count' do
      create(:quiz_submission, quiz: quiz, member: user, attempt_number: 1)
      create(:quiz_submission, quiz: quiz, member: user, attempt_number: 2)
      create(:quiz_submission, quiz: quiz, member: user, attempt_number: 3)
      expect(quiz.user_attempts(user)).to eq(3)
    end
  end

  describe '#user_can_attempt?' do
    let(:user) { create(:user) }

    context 'when quiz has high attempt limit' do
      before { quiz.update(max_attempts: 10) }

      it 'allows attempts when under limit' do
        create(:quiz_submission, quiz: quiz, member: user, attempt_number: 1)
        create(:quiz_submission, quiz: quiz, member: user, attempt_number: 2)
        expect(quiz.user_can_attempt?(user)).to be_truthy
      end
    end

    context 'when quiz has attempt limit' do
      before { quiz.update(max_attempts: 3) }

      it 'allows attempts when under limit' do
        create(:quiz_submission, quiz: quiz, member: user, attempt_number: 1)
        create(:quiz_submission, quiz: quiz, member: user, attempt_number: 2)
        expect(quiz.user_can_attempt?(user)).to be_truthy
      end

      it 'prevents attempts when limit reached' do
        create(:quiz_submission, quiz: quiz, member: user, attempt_number: 1)
        create(:quiz_submission, quiz: quiz, member: user, attempt_number: 2)
        create(:quiz_submission, quiz: quiz, member: user, attempt_number: 3)
        expect(quiz.user_can_attempt?(user)).to be_falsey
      end
    end
  end

  describe '#best_score' do
    let(:user) { create(:user) }

    it 'returns 0 when user has no submissions' do
      expect(quiz.best_score(user)).to eq(0)
    end

    it 'returns highest score' do
      create(:quiz_submission, quiz: quiz, member: user, percentage: 80, attempt_number: 1)
      create(:quiz_submission, quiz: quiz, member: user, percentage: 95, attempt_number: 2)
      create(:quiz_submission, quiz: quiz, member: user, percentage: 70, attempt_number: 3)
      expect(quiz.best_score(user)).to eq(95)
    end
  end

  describe '#has_passed?' do
    let(:user) { create(:user) }

    it 'returns false when no submissions' do
      expect(quiz.has_passed?(user)).to be_falsey
    end

    it 'returns true when best score meets passing percentage' do
      quiz.update(passing_percentage: 80)
      create(:quiz_submission, quiz: quiz, member: user, percentage: 85)
      expect(quiz.has_passed?(user)).to be_truthy
    end

    it 'returns false when best score below passing percentage' do
      quiz.update(passing_percentage: 80)
      create(:quiz_submission, quiz: quiz, member: user, percentage: 75)
      expect(quiz.has_passed?(user)).to be_falsey
    end
  end

  describe 'scopes' do
    describe '.published' do
      it 'returns only published quizzes' do
        published_quiz = create(:quiz, published: true)
        unpublished_quiz = create(:quiz, published: false)

        expect(LmsQuiz.published).to include(published_quiz)
        expect(LmsQuiz.published).not_to include(unpublished_quiz)
      end
    end
  end

  after(:each) do
    # Clean up data similar to Frappe tearDown
    LmsQuizSubmission.where(quiz: quiz).destroy_all
    LmsQuizQuestion.where(quiz: quiz).destroy_all
  end
end
