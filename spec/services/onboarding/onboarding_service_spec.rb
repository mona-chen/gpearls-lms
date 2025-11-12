require 'rails_helper'

RSpec.describe Onboarding::OnboardingService do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :moderator) }
  let(:course) { create(:course) }
  let(:chapter) { create(:chapter, course: course) }
  let(:lesson) { create(:lesson, chapter: chapter) }
  let(:quiz) { create(:quiz, course: course) }

  describe '.call' do
    context 'when user is not a moderator' do
      it 'returns onboarded status immediately' do
        result = described_class.call(user: user)

        expect(result[:is_onboarded]).to be true
      end
    end

    context 'when user is a moderator' do
      before do
        LmsSetting.set_onboarding_complete(false)
      end

      context 'with no content created' do
        it 'returns not onboarded with all flags false' do
          result = described_class.call(user: moderator)

          expect(result[:is_onboarded]).to be false
          expect(result[:course_created]).to be false
          expect(result[:chapter_created]).to be false
          expect(result[:lesson_created]).to be false
          expect(result[:quiz_created]).to be false
          expect(result[:first_course]).to be_nil
        end
      end

      context 'with partial content created' do
        before { course }

        it 'returns partial onboarding status' do
          result = described_class.call(user: moderator)

          expect(result[:is_onboarded]).to be false
          expect(result[:course_created]).to be true
          expect(result[:chapter_created]).to be false
          expect(result[:lesson_created]).to be false
          expect(result[:quiz_created]).to be false
          expect(result[:first_course]).to eq(course.title)
        end
      end

      context 'with all content created' do
        before do
          course
          chapter
          lesson
          quiz
        end

        it 'returns fully onboarded status' do
          result = described_class.call(user: moderator)

          expect(result[:is_onboarded]).to be true
          expect(result[:course_created]).to be true
          expect(result[:chapter_created]).to be true
          expect(result[:lesson_created]).to be true
          expect(result[:quiz_created]).to be true
          expect(result[:first_course]).to eq(course.title)
        end

        it 'updates LMS Settings to mark onboarding complete' do
          expect(LmsSetting.is_onboarding_complete).to be false

          described_class.call(user: moderator)

          expect(LmsSetting.is_onboarding_complete).to be true
        end
      end
    end
  end

  describe '#get_first_course' do
    context 'when no courses exist' do
      it 'returns nil' do
        service = described_class.new(user)
        expect(service.get_first_course).to be_nil
      end
    end

    context 'when courses exist' do
      before { course }

      it 'returns the first course title' do
        service = described_class.new(user)
        expect(service.get_first_course).to eq(course.title)
      end
    end
  end

  describe '#get_first_batch' do
    let(:batch) { create(:batch) }

    context 'when no batches exist' do
      it 'returns nil' do
        service = described_class.new(user)
        expect(service.get_first_batch).to be_nil
      end
    end

    context 'when batches exist' do
      before { batch }

      it 'returns the first batch title' do
        service = described_class.new(user)
        expect(service.get_first_batch).to eq(batch.title)
      end
    end
  end

  describe '#has_course_moderator_role?' do
    context 'when user is nil' do
      it 'returns false' do
        service = described_class.new(nil)
        expect(service.send(:has_course_moderator_role?)).to be false
      end
    end

    context 'when user has Moderator role' do
      it 'returns true' do
        service = described_class.new(moderator)
        expect(service.send(:has_course_moderator_role?)).to be true
      end
    end

    context 'when user has other roles but not Moderator' do
      let(:course_creator) { create(:user, :course_creator) }
      let(:student) { create(:user, :student) }

      it 'returns false for Course Creator' do
        service = described_class.new(course_creator)
        expect(service.send(:has_course_moderator_role?)).to be false
      end

      it 'returns false for Student' do
        service = described_class.new(student)
        expect(service.send(:has_course_moderator_role?)).to be false
      end
    end

    context 'when user has no roles' do
      it 'returns false' do
        service = described_class.new(user)
        expect(service.send(:has_course_moderator_role?)).to be false
      end
    end
  end

  describe 'private methods' do
    let(:service) { described_class.new(moderator) }

    describe '#is_onboarding_complete' do
      before do
        LmsSetting.set_onboarding_complete(false)
      end

      context 'with all content types created' do
        before do
          course
          chapter
          lesson
          quiz
        end

        it 'updates onboarding status to complete' do
          expect(LmsSetting.is_onboarding_complete).to be false
          service.send(:is_onboarding_complete)
          expect(LmsSetting.is_onboarding_complete).to be true
        end
      end

      context 'with missing content types' do
        before { course }

        it 'does not update onboarding status' do
          expect(LmsSetting.is_onboarding_complete).to be false
          service.send(:is_onboarding_complete)
          expect(LmsSetting.is_onboarding_complete).to be false
        end
      end
    end
  end

  describe 'integration with LmsSetting' do
    it 'uses LmsSetting methods correctly' do
      expect(LmsSetting).to receive(:is_onboarding_complete).and_return(false)
      expect(LmsSetting).to receive(:set_onboarding_complete).with(true)

      course
      chapter
      lesson
      quiz

      described_class.call(user: moderator)
    end
  end

  describe 'performance considerations' do
    it 'uses efficient queries for content existence checks' do
      expect(Course).to receive(:exists?).once.and_return(true)
      expect(Chapter).to receive(:exists?).once.and_return(true)
      expect(Lesson).to receive(:exists?).once.and_return(true)
      expect(Quiz).to receive(:exists?).once.and_return(true)

      described_class.call(user: moderator)
    end

    it 'uses efficient query for first course' do
      expect(Course).to receive(:select).with(:title).once.and_call_original
      expect_any_instance_of(ActiveRecord::Relation).to receive(:order).with(:created_at).once.and_call_original
      expect_any_instance_of(ActiveRecord::Relation).to receive(:first).once.and_call_original

      service = described_class.new(user)
      service.get_first_course
    end
  end
end
