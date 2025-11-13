require 'rails_helper'

RSpec.describe LmsQuestion, type: :model do
  let(:quiz) { create(:quiz) }
  let(:question) { build(:lms_question, quiz: quiz) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      question.question = 'Test Question'
      question.question_type = 'Choices'
      question.option_1 = 'Option 1'
      question.is_correct_1 = true
      question.option_2 = 'Option 2'
      expect(question).to be_valid
    end

    it 'is invalid without a question' do
      question.question = nil
      expect(question).to_not be_valid
    end

    it 'is invalid without a question type' do
      question.question_type = nil
      expect(question).to_not be_valid
    end
  end

  describe 'multiple choice questions' do
    context 'with multiple correct options' do
      it 'sets multiple to true' do
        question.question = 'Question Multiple'
        question.question_type = 'Choices'
        question.option_1 = 'Option 1'
        question.is_correct_1 = true
        question.option_2 = 'Option 2'
        question.is_correct_2 = true
        question.save!
        expect(question.multiple).to be_truthy
      end
    end

    context 'with single correct option' do
      it 'sets multiple to false' do
        question.question = 'Question Single'
        question.question_type = 'Choices'
        question.option_1 = 'Option 1'
        question.is_correct_1 = true
        question.option_2 = 'Option 2'
        question.is_correct_2 = false
        question.save!
        expect(question.multiple).to be_falsey
      end
    end

    context 'with no correct options' do
      it 'raises validation error' do
        question.question = 'Question Multiple'
        question.question_type = 'Choices'
        question.option_1 = 'Option 1'
        question.option_2 = 'Option 2'
        # No correct options set
        expect { question.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe 'user input questions' do
    context 'without possible answers' do
      it 'raises validation error' do
        question.question = 'Question User Input'
        question.question_type = 'User Input'
        # No possible answers provided
        expect { question.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with possible answers' do
      it 'is valid' do
        question.question = 'Question User Input'
        question.question_type = 'User Input'
        question.possible_answers = ['answer1', 'answer2']
        expect(question).to be_valid
      end
    end
  end

  describe '#correct_options' do
    it 'returns array of correct option numbers' do
      question.question_type = 'Choices'
      question.option_1 = 'Option 1'
      question.is_correct_1 = true
      question.option_2 = 'Option 2'
      question.is_correct_2 = false
      question.option_3 = 'Option 3'
      question.is_correct_3 = true
      
      expect(question.correct_options).to contain_exactly(1, 3)
    end
  end

  describe '#options' do
    it 'returns hash of non-empty options' do
      question.option_1 = 'Option 1'
      question.option_2 = 'Option 2'
      question.option_3 = ''
      question.option_4 = nil
      
      expected_options = {
        1 => 'Option 1',
        2 => 'Option 2'
      }
      
      expect(question.options).to eq(expected_options)
    end
  end

  describe '#check_answer' do
    context 'for choices question' do
      before do
        question.question_type = 'Choices'
        question.option_1 = 'Option 1'
        question.is_correct_1 = true
        question.option_2 = 'Option 2'
        question.is_correct_2 = false
        question.save!
      end

      it 'returns true for correct answer' do
        expect(question.check_answer(['1'])).to be_truthy
      end

      it 'returns false for incorrect answer' do
        expect(question.check_answer(['2'])).to be_falsey
      end

      it 'handles multiple correct answers' do
        question.update!(is_correct_2: true)
        expect(question.check_answer(['1', '2'])).to be_truthy
        expect(question.check_answer(['1'])).to be_falsey # incomplete
      end
    end

    context 'for user input question' do
      before do
        question.question_type = 'User Input'
        question.possible_answers = ['correct answer', 'another correct']
        question.save!
      end

      it 'returns true for correct answer' do
        expect(question.check_answer('correct answer')).to be_truthy
      end

      it 'returns true for case-insensitive match' do
        expect(question.check_answer('CORRECT ANSWER')).to be_truthy
      end

      it 'returns false for incorrect answer' do
        expect(question.check_answer('wrong answer')).to be_falsey
      end
    end
  end

  describe 'associations' do
    it 'belongs to quiz' do
      expect(question).to respond_to(:quiz)
    end
  end

  describe 'scopes' do
    describe '.by_type' do
      let!(:choice_question) { create(:lms_question, question_type: 'Choices') }
      let!(:input_question) { create(:lms_question, question_type: 'User Input') }

      it 'returns questions of specified type' do
        expect(LmsQuestion.by_type('Choices')).to include(choice_question)
        expect(LmsQuestion.by_type('Choices')).not_to include(input_question)
      end
    end
  end
end