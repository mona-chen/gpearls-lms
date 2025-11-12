# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Courses::CourseReviewService, type: :service do
  let(:instructor) { create(:user, :instructor) }
  let(:student) { create(:user) }
  let(:course) { create(:course, :published, instructor: instructor) }
  let!(:enrollment) { create(:enrollment, user: student, course: course) }

  describe '.get_reviews' do
    context 'with course that has reviews' do
      let!(:review1) { create(:course_review, course: course, owner: student.email, rating: 5, review: 'Great course!') }
      let!(:review2) { create(:course_review, course: course, owner: 'other@example.com', rating: 4, review: 'Good content') }

      it 'returns all reviews for the course' do
        result = described_class.get_reviews(course)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
      end

      it 'returns reviews in correct format' do
        result = described_class.get_reviews(course)

        review_data = result.first
        expect(review_data['name']).to be_a(String)
        expect(review_data['review']).to eq('Great course!')
        expect(review_data['rating']).to eq(5)
        expect(review_data['owner']).to eq(student.email)
        expect(review_data['course']).to eq(course.name)
        expect(review_data['course_title']).to eq(course.title)
        expect(review_data['creation']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end

      it 'orders reviews by creation date descending' do
        # Create another review with a later timestamp
        review3 = create(:course_review, course: course, owner: 'third@example.com', rating: 3, review: 'Okay')

        result = described_class.get_reviews(course)

        expect(result.first['owner']).to eq('third@example.com')
        expect(result.last['owner']).to eq(student.email)
      end

      it 'limits results to 50 reviews' do
        create_list(:course_review, 60, course: course)

        result = described_class.get_reviews(course)

        expect(result.length).to eq(50)
      end
    end

    context 'with course that has no reviews' do
      it 'returns empty array' do
        result = described_class.get_reviews(course)

        expect(result).to eq([])
      end
    end

    context 'with nil course' do
      it 'returns empty array' do
        result = described_class.get_reviews(nil)

        expect(result).to eq([])
      end
    end

    context 'with unpublished reviews' do
      let!(:unpublished_review) { create(:course_review, course: course, docstatus: '1') }

      it 'only returns published reviews' do
        result = described_class.get_reviews(course)

        expect(result).to be_empty
      end
    end
  end

  describe '.add_review' do
    context 'with valid parameters' do
      it 'creates review successfully' do
        result = described_class.add_review(student, course, 5, 'Excellent course!')

        expect(result[:success]).to be true
        expect(result[:review]).to be_a(Hash)
        expect(result[:message]).to eq('Review submitted successfully')
      end

      it 'creates review record in database' do
        expect {
          described_class.add_review(student, course, 4, 'Good course')
        }.to change(CourseReview, :count).by(1)

        review = CourseReview.last
        expect(review.course).to eq(course)
        expect(review.owner).to eq(student.email)
        expect(review.rating).to eq(4)
        expect(review.review).to eq('Good course')
        expect(review.docstatus).to eq('0') # published
      end

      it 'returns Frappe-compatible review data' do
        result = described_class.add_review(student, course, 5)

        review_data = result[:review]
        expect(review_data['name']).to be_a(String)
        expect(review_data['owner']).to eq(student.email)
        expect(review_data['rating']).to eq(5)
        expect(review_data['course']).to eq(course.name)
        expect(review_data['docstatus']).to eq('0')
      end

      it 'allows review without text' do
        result = described_class.add_review(student, course, 3)

        expect(result[:success]).to be true
        expect(CourseReview.last.review).to be_nil
      end
    end

    context 'with invalid parameters' do
      it 'returns error for nil user' do
        result = described_class.add_review(nil, course, 5, 'Review')

        expect(result[:success]).to be false
        expect(result[:error]).to eq('User not authenticated')
      end

      it 'returns error for nil course' do
        result = described_class.add_review(student, nil, 5, 'Review')

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Course not found')
      end

      it 'returns error for invalid rating' do
        result = described_class.add_review(student, course, 6, 'Review')

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Invalid rating')
      end

      it 'returns error for unenrolled user' do
        unenrolled_student = create(:user)

        result = described_class.add_review(unenrolled_student, course, 5, 'Review')

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Must be enrolled in course to leave a review')
      end

      it 'prevents duplicate reviews from same user' do
        described_class.add_review(student, course, 5, 'First review')

        result = described_class.add_review(student, course, 4, 'Second review')

        expect(result[:success]).to be false
        expect(result[:error]).to eq('You have already reviewed this course')
      end
    end
  end

  describe '.get_average_rating' do
    context 'with reviews' do
      before do
        create(:course_review, course: course, rating: 5)
        create(:course_review, course: course, rating: 3)
      end

      it 'calculates average rating correctly' do
        result = described_class.get_average_rating(course)

        expect(result).to eq(4.0)
      end
    end

    context 'without reviews' do
      it 'returns 0.0' do
        result = described_class.get_average_rating(course)

        expect(result).to eq(0.0)
      end
    end

    context 'with nil course' do
      it 'returns 0.0' do
        result = described_class.get_average_rating(nil)

        expect(result).to eq(0.0)
      end
    end
  end
end
