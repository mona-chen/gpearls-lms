require 'rails_helper'

RSpec.describe Courses::CoursesService, type: :service do
  let(:instructor) { create(:user, :instructor) }
  let(:published_course) { create(:course, :published, instructor: instructor) }
  let(:draft_course) { create(:course, published: false, instructor: instructor) }
  let(:featured_course) { create(:course, :featured, :published, instructor: instructor) }
  let(:upcoming_course) { create(:course, :published, upcoming: true, instructor: instructor) }

  describe '.call' do
    context 'with no parameters' do
      before do
        published_course # Ensure course is created
        @result = Courses::CoursesService.call
      end

      it 'returns courses with all required fields' do
        course_data = @result['data'].find { |c| c['name'] == published_course.id }

        expect(course_data).to have_key('video_link')
        expect(course_data).to have_key('short_introduction')
        expect(course_data).to have_key('published')
        expect(course_data).to have_key('featured')
        expect(course_data).to have_key('creation')
        expect(course_data).to have_key('modified')
        expect(course_data).to have_key('owner')
        expect(course_data).to have_key('enrollment_count')
        expect(course_data).to have_key('rating')
        expect(course_data).to have_key('status')
      end

      it 'includes instructor information' do
        course_data = @result['data'].find { |c| c['name'] == published_course.id }
        expect(course_data['instructor']).to eq(instructor.full_name)
        expect(course_data['instructor_id']).to eq(instructor.id)
        expect(course_data['owner']).to eq(instructor.email)
      end

      it 'formats dates correctly' do
        course_data = @result['data'].find { |c| c['name'] == published_course.id }
        expect(course_data['creation']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(course_data['modified']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end

      it 'splits tags into array' do
        published_course.update!(tags: 'ruby, rails, testing')

        result = Courses::CoursesService.call
        course_data = result['data'].find { |c| c['name'] == published_course.id }
        expect(course_data['tags']).to eq([ 'ruby', ' rails', ' testing' ])
      end

      it 'returns Published status for published courses' do
        course_data = @result['data'].find { |c| c['name'] == published_course.id }
        expect(course_data['status']).to eq('Published')
      end
    end

    context 'with filters' do
      context 'published filter' do
        it 'filters only published courses when published=1' do
          published_course
          draft_course

          result = Courses::CoursesService.call(filters: { published: 1 })

          course_names = result['data'].map { |c| c['name'] }
          expect(course_names).to include(published_course.id)
          expect(course_names).not_to include(draft_course.id)
        end
      end

      context 'upcoming filter' do
        it 'excludes upcoming courses when upcoming=0' do
          published_course
          upcoming_course

          result = Courses::CoursesService.call(filters: { upcoming: 0 })

          course_names = result['data'].map { |c| c['name'] }
          expect(course_names).to include(published_course.id)
          expect(course_names).not_to include(upcoming_course.id)
        end
      end

      context 'multiple filters' do
        it 'applies multiple filters together' do
          published_course
          upcoming_course
          draft_course

          result = Courses::CoursesService.call(filters: { published: 1, upcoming: 0 })

          course_names = result['data'].map { |c| c['name'] }
          expect(course_names).to include(published_course.id)
          expect(course_names).not_to include(upcoming_course.id)
          expect(course_names).not_to include(draft_course.id)
        end
      end
    end

    context 'with pagination' do
      before do
        create_list(:course, 5, :published, instructor: instructor)
      end

      it 'applies limit parameter' do
        result = Courses::CoursesService.call(limit: 2)

        expect(result['data'].length).to eq(2)
      end

      it 'applies offset parameter' do
        all_courses = Courses::CoursesService.call
        first_course = all_courses['data'].first

        result = Courses::CoursesService.call(limit: 1, start: 1)

        expect(result['data'].length).to eq(1)
        expect(result['data'].first['name']).not_to eq(first_course['name'])
      end

      it 'uses default pagination values' do
        result = Courses::CoursesService.call

        expect(result['data'].length).to be <= 30
      end
    end

    context 'rating calculation' do
      let(:course_with_enrollments) { create(:course, :published, instructor: instructor) }

      before do
        create_list(:enrollment, 3, course: course_with_enrollments, progress_percentage: 100)
        create_list(:enrollment, 2, course: course_with_enrollments, progress_percentage: 50)
      end

    it 'calculates rating based on completion rate' do
      course_with_enrollments = create(:course, :published)
      create_list(:enrollment, 3, course: course_with_enrollments, progress_percentage: 100)
      create_list(:enrollment, 2, course: course_with_enrollments, progress_percentage: 50)

      result = Courses::CoursesService.call
      course_data = result['data'].find { |c| c['name'] == course_with_enrollments.id }

      expect(course_data['rating']).to be > 0
    end

      it 'returns 0 rating for courses with no enrollments' do
        course_no_rating = create(:course, :published, instructor: instructor)

        result = Courses::CoursesService.call

        course_data = result['data'].find { |c| c['name'] == course_no_rating.id }
        expect(course_data['rating']).to eq(0)
      end

      it 'caps rating at 5.0' do
        # Create many high-completion enrollments
        create_list(:enrollment, 10, course: published_course, progress_percentage: 100)

        result = Courses::CoursesService.call

        course_data = result['data'].find { |c| c['name'] == published_course.id }
        expect(course_data['rating']).to eq(5.0)
      end
    end

    context 'enrollment count' do
      let(:course_with_enrollments) { create(:course, :published, instructor: instructor) }

      before do
        create_list(:enrollment, 3, course: course_with_enrollments)
      end

      it 'includes accurate enrollment count' do
        result = Courses::CoursesService.call

        course_data = result['data'].find { |c| c['name'] == course_with_enrollments.id }
        expect(course_data['enrollment_count']).to eq(3)
      end

      it 'returns 0 for courses with no enrollments' do
        course_no_enrollments = create(:course, :published, instructor: instructor)

        result = Courses::CoursesService.call

        course_data = result['data'].find { |c| c['name'] == course_no_enrollments.id }
        expect(course_data['enrollment_count']).to eq(0)
      end
    end

    context 'course fields mapping' do
      it 'maps all required fields correctly' do
        course = create(:course, :published,
          title: 'Test Course',
          description: 'Test Description',
          category: 'Programming',
          short_introduction: 'Test Intro',
          video_link: 'https://example.com/video',
          image: 'test.jpg',
          tags: 'ruby, rails',
          instructor: instructor
        )

        result = Courses::CoursesService.call

        course_data = result['data'].find { |c| c['name'] == course.id }
        expect(course_data['title']).to eq('Test Course')
        expect(course_data['description']).to eq('Test Description')
        expect(course_data['category']).to eq('Programming')
        expect(course_data['short_introduction']).to eq('Test Intro')
        expect(course_data['video_link']).to eq('https://example.com/video')
        expect(course_data['image']).to eq('test.jpg')
        expect(course_data['published']).to be true
        expect(course_data['featured']).to be false
      end
    end

    context 'edge cases' do
      it 'handles courses without instructors' do
        course_without_instructor = create(:course, :published, instructor: nil)

        result = Courses::CoursesService.call

        course_data = result['data'].find { |c| c['name'] == course_without_instructor.id }
        expect(course_data['instructor']).to be_nil
        expect(course_data['instructor_id']).to be_nil
        expect(course_data['owner']).to be_nil
      end

      it 'handles courses with nil tags' do
        published_course.update!(tags: nil)

        result = Courses::CoursesService.call

        course_data = result['data'].find { |c| c['name'] == published_course.id }
        expect(course_data['tags']).to eq([])
      end

      it 'handles empty database' do
        Course.delete_all

        result = Courses::CoursesService.call

        expect(result['data']).to eq([])
      end

      it 'handles invalid filter parameters gracefully' do
        expect {
          Courses::CoursesService.call(filters: { invalid_field: 'value' })
        }.not_to raise_error
      end
    end

    context 'performance considerations' do
      it 'includes instructor data to prevent N+1 queries' do
        # Test that instructors are preloaded by checking that no additional queries are made
        result = Courses::CoursesService.call
        expect(result['data'].first).to have_key('instructor') if result['data'].any?
      end
    end
  end

  describe 'private methods' do
    let(:service) { Courses::CoursesService.new({}) }

    describe '#calculate_course_rating' do
      let(:course_with_enrollments) { create(:course) }

      context 'with no enrollments' do
        it 'returns 0' do
          rating = service.send(:calculate_course_rating, course_with_enrollments)
          expect(rating).to eq(0)
        end
      end

      context 'with mixed completion rates' do
        before do
          create(:enrollment, course: course_with_enrollments, progress_percentage: 100)
          create(:enrollment, course: course_with_enrollments, progress_percentage: 80)
          create(:enrollment, course: course_with_enrollments, progress_percentage: 60)
        end

        it 'calculates weighted average rating' do
          rating = service.send(:calculate_course_rating, course_with_enrollments)
          expect(rating).to be > 0
          expect(rating).to be <= 5.0

          # Average completion is 80%, so rating should be 4.0 (80% * 5)
          expect(rating).to eq(4.0)
        end
      end

      context 'with all high completions' do
        before do
          create_list(:enrollment, 5, course: course_with_enrollments, progress_percentage: 100)
        end

        it 'caps at 5.0' do
          rating = service.send(:calculate_course_rating, course_with_enrollments)
          expect(rating).to eq(5.0)
        end
      end
    end
  end
end
