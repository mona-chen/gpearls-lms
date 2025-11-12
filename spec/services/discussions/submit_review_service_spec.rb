require 'rails_helper'

RSpec.describe Discussions::SubmitReviewService, type: :service do
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let!(:enrollment) { create(:enrollment, user: user, course: course, completed: true) }

  describe '.call' do
    context 'successful review submission' do
      let(:params) { { course: course.id, content: 'Great course!' } }

      it 'creates a review message' do
        expect {
          result = described_class.call(params, user)
          expect(result[:success]).to be_truthy
        }.to change(Message, :count).by(1)
      end

      it 'creates or updates course review' do
        expect {
          result = described_class.call(params, user)
          expect(result[:success]).to be_truthy
        }.to change(CourseReview, :count).by(1)
      end

      it 'returns success response with review data' do
        result = described_class.call(params, user)

        expect(result[:success]).to be_truthy
        expect(result[:data]).to be_a(Message)
        expect(result[:message]).to eq('Review submitted successfully')
      end

      it 'sets message type to review' do
        result = described_class.call(params, user)

        message = result[:data]
        expect(message.message_type).to eq('review')
        expect(message.content).to eq('Great course!')
        expect(message.user).to eq(user)
        expect(message.discussion).to be_nil # Reviews are not attached to discussions
      end

      it 'includes rating if provided' do
        params_with_rating = params.merge(rating: 5)
        result = described_class.call(params_with_rating, user)

        message = result[:data]
        expect(message.rating).to eq(5)

        course_review = CourseReview.last
        expect(course_review.rating).to eq(5)
        expect(course_review.review).to eq('Great course!')
      end
    end

    context 'validation failures' do
      it 'fails for nil user' do
        result = described_class.call({ course: course.id, content: 'test' }, nil)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('User not found')
      end

      it 'fails for missing course' do
        result = described_class.call({ content: 'test' }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Course is required')
      end

      it 'fails for missing content' do
        result = described_class.call({ course: course.id }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Review content is required')
      end

      it 'fails for non-existent course' do
        result = described_class.call({ course: 'non-existent', content: 'test' }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Course not found')
      end

      it 'fails if user is not enrolled in course' do
        other_course = create(:course)
        result = described_class.call({ course: other_course.id, content: 'test' }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('User is not enrolled in this course')
      end

      it 'fails if course is not completed' do
        enrollment.update(completed: false)
        result = described_class.call({ course: course.id, content: 'test' }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Course not completed')
      end

      it 'fails if review already exists' do
        create(:message, user: user, message_type: 'review', content: 'Existing review')
        result = described_class.call({ course: course.id, content: 'New review' }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Review already submitted for this course')
      end
    end

    context 'course review creation' do
      it 'creates new course review' do
        params = { course: course.id, content: 'Great course!', rating: 4 }
        result = described_class.call(params, user)

        expect(result[:success]).to be_truthy

        course_review = CourseReview.last
        expect(course_review.user).to eq(user)
        expect(course_review.course).to eq(course)
        expect(course_review.review).to eq('Great course!')
        expect(course_review.rating).to eq(4)
      end

      it 'updates existing course review' do
        existing_review = create(:course_review, user: user, course: course, rating: 3, review: 'Old review')

        params = { course: course.id, content: 'Updated review!', rating: 5 }
        result = described_class.call(params, user)

        expect(result[:success]).to be_truthy

        existing_review.reload
        expect(existing_review.review).to eq('Updated review!')
        expect(existing_review.rating).to eq(5)
      end
    end

    context 'Frappe API compatibility' do
      it 'returns proper success response format' do
        params = { course: course.id, content: 'test review' }
        result = described_class.call(params, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:data)
        expect(result).to have_key(:message)
        expect(result[:success]).to be_truthy
      end

      it 'returns proper error response format' do
        result = described_class.call({}, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:error)
        expect(result).to have_key(:message)
        expect(result[:success]).to be_falsey
      end
    end
  end
end
