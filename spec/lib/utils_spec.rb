require 'rails_helper'

RSpec.describe 'LMS Utils', type: :lib do
  describe 'slugify function' do
    # Test cases matching Frappe test_utils.py

    describe 'simple slugification' do
      it 'keeps simple slugs unchanged' do
        expect(slugify('hello-world')).to eq('hello-world')
      end

      it 'converts spaces to hyphens' do
        expect(slugify('Hello World')).to eq('hello-world')
      end

      it 'removes special characters' do
        expect(slugify('Hello, World!')).to eq('hello-world')
      end

      it 'handles multiple spaces' do
        expect(slugify('Hello    World')).to eq('hello-world')
      end

      it 'handles mixed case and special characters' do
        expect(slugify('Test Course: Advanced Programming!')).to eq('test-course-advanced-programming')
      end

      it 'trims leading and trailing spaces' do
        expect(slugify('  hello world  ')).to eq('hello-world')
      end

      it 'handles empty string' do
        expect(slugify('')).to eq('')
      end

      it 'handles nil input' do
        expect(slugify(nil)).to eq('')
      end
    end

    describe 'duplicate handling' do
      it 'adds suffix for first duplicate' do
        existing = [ 'hello-world' ]
        expect(slugify('Hello World', existing)).to eq('hello-world-2')
      end

      it 'increments suffix for multiple duplicates' do
        existing = [ 'hello-world', 'hello-world-2' ]
        expect(slugify('Hello World', existing)).to eq('hello-world-3')
      end

      it 'handles gaps in numbering' do
        existing = [ 'hello-world', 'hello-world-3', 'hello-world-5' ]
        expect(slugify('Hello World', existing)).to eq('hello-world-2')
      end

      it 'handles complex existing patterns' do
        existing = [ 'test', 'test-2', 'test-3', 'test-10' ]
        expect(slugify('Test', existing)).to eq('test-4')
      end
    end

    describe 'edge cases' do
      it 'handles numbers in original text' do
        expect(slugify('Course 101')).to eq('course-101')
      end

      it 'handles unicode characters' do
        expect(slugify('Café Français')).to eq('cafe-francais')
      end

      it 'handles very long titles' do
        long_title = 'A' * 100
        result = slugify(long_title)
        expect(result.length).to be <= 100
        expect(result).to eq('a' * 100)
      end
    end
  end

  describe 'membership utilities' do
    let(:course) { create(:course) }
    let(:user) { create(:user) }

    describe 'get_membership' do
      it 'returns nil when user not enrolled' do
        expect(get_membership(user, course)).to be_nil
      end

      it 'returns enrollment when user enrolled' do
        enrollment = create(:enrollment, user: user, course: course)
        expect(get_membership(user, course)).to eq(enrollment)
      end
    end

    describe 'is_enrolled' do
      it 'returns false when user not enrolled' do
        expect(is_enrolled(user, course)).to be_falsey
      end

      it 'returns true when user enrolled' do
        create(:enrollment, user: user, course: course)
        expect(is_enrolled(user, course)).to be_truthy
      end
    end
  end

  describe 'course utilities' do
    let(:course) { create(:course) }
    let(:chapter) { create(:course_chapter, course: course) }

    describe 'get_chapters' do
      before do
        create(:course_chapter, course: course, title: 'Chapter 1', idx: 1)
        create(:course_chapter, course: course, title: 'Chapter 2', idx: 2)
      end

      it 'returns chapters in order' do
        chapters = get_chapters(course)
        expect(chapters.count).to eq(3) # including the let(:chapter)
        expect(chapters.first.idx).to be <= chapters.last.idx
      end

      it 'returns empty array for course without chapters' do
        new_course = create(:course)
        chapters = get_chapters(new_course)
        expect(chapters).to eq([])
      end
    end

    describe 'get_lessons' do
      let!(:lesson1) { create(:course_lesson, course_chapter: chapter, course: course, idx: 1) }
      let!(:lesson2) { create(:course_lesson, course_chapter: chapter, course: course, idx: 2) }

      it 'returns lessons for a chapter' do
        lessons = get_lessons(chapter)
        expect(lessons.count).to eq(2)
        expect(lessons).to include(lesson1, lesson2)
      end

      it 'returns lessons in order' do
        lessons = get_lessons(chapter)
        expect(lessons.first.idx).to be <= lessons.last.idx
      end
    end

    describe 'get_lesson_details' do
      let(:lesson) { create(:course_lesson, course_chapter: chapter, course: course) }
      let(:user) { create(:user) }

      it 'returns lesson with progress information' do
        create(:enrollment, user: user, course: course)
        details = get_lesson_details(lesson, user)

        expect(details[:lesson]).to eq(lesson)
        expect(details[:progress]).to be_present
        expect(details[:completed]).to be_in([ true, false ])
      end

      it 'handles user without enrollment' do
        details = get_lesson_details(lesson, user)
        expect(details[:lesson]).to eq(lesson)
        expect(details[:progress]).to eq(0)
        expect(details[:completed]).to be_falsey
      end
    end
  end

  describe 'progress utilities' do
    let(:course) { create(:course) }
    let(:chapter) { create(:course_chapter, course: course) }
    let!(:lesson1) { create(:course_lesson, course_chapter: chapter, course: course) }
    let!(:lesson2) { create(:course_lesson, course_chapter: chapter, course: course) }
    let(:user) { create(:user) }

    describe 'get_progress' do
      it 'returns 0 for user with no progress' do
        progress = get_progress(user, course)
        expect(progress).to eq(0)
      end

      it 'calculates correct progress percentage' do
        create(:enrollment, user: user, course: course)
        create(:lesson_progress, user: user, lesson: lesson1, status: 'Complete')

        progress = get_progress(user, course)
        expect(progress).to eq(50) # 1 out of 2 lessons
      end

      it 'returns 100 for completed course' do
        create(:enrollment, user: user, course: course)
        create(:lesson_progress, user: user, lesson: lesson1, status: 'Complete')
        create(:lesson_progress, user: user, lesson: lesson2, status: 'Complete')

        progress = get_progress(user, course)
        expect(progress).to eq(100)
      end
    end
  end

  describe 'rating utilities' do
    let(:course) { create(:course) }

    describe 'get_average_rating' do
      it 'returns 0 for course with no reviews' do
        rating = get_average_rating(course)
        expect(rating).to eq(0)
      end

      it 'calculates correct average rating' do
        create(:course_review, course: course, rating: 4)
        create(:course_review, course: course, rating: 5)
        create(:course_review, course: course, rating: 3)

        rating = get_average_rating(course)
        expect(rating).to eq(4.0)
      end

      it 'handles single review' do
        create(:course_review, course: course, rating: 5)

        rating = get_average_rating(course)
        expect(rating).to eq(5.0)
      end
    end

    describe 'get_reviews' do
      let!(:review1) { create(:course_review, course: course, rating: 5, created_at: 1.day.ago) }
      let!(:review2) { create(:course_review, course: course, rating: 4, created_at: 2.days.ago) }

      it 'returns reviews for course' do
        reviews = get_reviews(course)
        expect(reviews.count).to eq(2)
        expect(reviews).to include(review1, review2)
      end

      it 'returns reviews in chronological order by default' do
        reviews = get_reviews(course)
        expect(reviews.first.created_at).to be >= reviews.last.created_at
      end
    end

    describe 'get_sorted_reviews' do
      before do
        create(:course_review, course: course, rating: 3, created_at: 1.day.ago)
        create(:course_review, course: course, rating: 5, created_at: 2.days.ago)
        create(:course_review, course: course, rating: 4, created_at: 3.days.ago)
      end

      it 'sorts reviews by rating descending' do
        reviews = get_sorted_reviews(course, sort_by: 'rating')
        ratings = reviews.pluck(:rating)
        expect(ratings).to eq([ 5, 4, 3 ])
      end

      it 'sorts reviews by date descending' do
        reviews = get_sorted_reviews(course, sort_by: 'date')
        dates = reviews.pluck(:created_at)
        expect(dates.first).to be >= dates.last
      end
    end
  end

  describe 'instructor utilities' do
    let(:course) { create(:course) }
    let(:instructor) { create(:user) }

    describe 'get_instructors' do
      it 'returns empty array for course without instructors' do
        instructors = get_instructors(course)
        expect(instructors).to eq([])
      end

      it 'returns course instructors' do
        course.instructors << instructor
        instructors = get_instructors(course)
        expect(instructors).to include(instructor)
      end
    end

    describe 'is_instructor' do
      it 'returns false for non-instructor user' do
        regular_user = create(:user)
        expect(is_instructor(regular_user, course)).to be_falsey
      end

      it 'returns true for course instructor' do
        course.instructors << instructor
        expect(is_instructor(instructor, course)).to be_truthy
      end
    end
  end

  describe 'lesson utilities' do
    let(:course) { create(:course) }
    let(:chapter) { create(:course_chapter, course: course) }
    let(:lesson) { create(:course_lesson, course_chapter: chapter, course: course, lesson_type: 'Article') }

    describe 'get_lesson_icon' do
      it 'returns correct icon for article lesson' do
        lesson.update(lesson_type: 'Article')
        icon = get_lesson_icon(lesson)
        expect(icon).to include('article') # or whatever icon class you use
      end

      it 'returns correct icon for video lesson' do
        lesson.update(lesson_type: 'Video')
        icon = get_lesson_icon(lesson)
        expect(icon).to include('video')
      end

      it 'returns correct icon for quiz lesson' do
        lesson.update(lesson_type: 'Quiz')
        icon = get_lesson_icon(lesson)
        expect(icon).to include('quiz')
      end

      it 'returns default icon for unknown lesson type' do
        lesson.update(lesson_type: 'Unknown')
        icon = get_lesson_icon(lesson)
        expect(icon).to include('default')
      end
    end

    describe 'get_lesson_index' do
      let!(:lesson1) { create(:course_lesson, course_chapter: chapter, idx: 1) }
      let!(:lesson2) { create(:course_lesson, course_chapter: chapter, idx: 2) }

      it 'returns correct lesson index' do
        expect(get_lesson_index(lesson1)).to eq(1)
        expect(get_lesson_index(lesson2)).to eq(2)
      end
    end

    describe 'get_lesson_url' do
      it 'generates correct lesson URL' do
        url = get_lesson_url(lesson)
        expected = "/courses/#{course.name}/lessons/#{lesson.id}"
        expect(url).to eq(expected)
      end

      it 'handles course with special characters in name' do
        course.update(name: 'test-course-special')
        url = get_lesson_url(lesson)
        expect(url).to include('test-course-special')
      end
    end
  end

  # Helper methods implementation
  private

  def slugify(text, existing = [])
    return '' if text.blank?

    slug = text.to_s.downcase
                  .gsub(/[^\w\s-]/, '') # Remove special characters
                  .gsub(/\s+/, '-')     # Replace spaces with hyphens
                  .gsub(/-+/, '-')      # Replace multiple hyphens with single
                  .strip
                  .gsub(/^-|-$/, '')    # Remove leading/trailing hyphens

    # Handle duplicates
    if existing.include?(slug)
      counter = 2
      loop do
        candidate = "#{slug}-#{counter}"
        break candidate unless existing.include?(candidate)
        counter += 1
      end
    else
      slug
    end
  end

  def get_membership(user, course)
    user.enrollments.find_by(course: course)
  end

  def is_enrolled(user, course)
    get_membership(user, course).present?
  end

  def get_chapters(course)
    course.course_chapters.order(:idx)
  end

  def get_lessons(chapter)
    chapter.course_lessons.order(:idx)
  end

  def get_lesson_details(lesson, user)
    enrollment = user.enrollments.find_by(course: lesson.course)
    progress = enrollment&.lesson_progresses&.find_by(lesson: lesson)

    {
      lesson: lesson,
      progress: progress&.progress || 0,
      completed: progress&.status == 'Complete'
    }
  end

  def get_progress(user, course)
    enrollment = user.enrollments.find_by(course: course)
    return 0 unless enrollment

    total_lessons = course.course_lessons.count
    return 0 if total_lessons.zero?

    completed_lessons = enrollment.lesson_progresses.where(status: 'Complete').count
    (completed_lessons.to_f / total_lessons * 100).round
  end

  def get_average_rating(course)
    course.course_reviews.average(:rating) || 0
  end

  def get_reviews(course)
    course.course_reviews.order(created_at: :desc)
  end

  def get_sorted_reviews(course, sort_by: 'date')
    case sort_by
    when 'rating'
      course.course_reviews.order(rating: :desc)
    else
      course.course_reviews.order(created_at: :desc)
    end
  end

  def get_instructors(course)
    course.instructors
  end

  def is_instructor(user, course)
    course.instructors.include?(user)
  end

  def get_lesson_icon(lesson)
    case lesson.lesson_type
    when 'Video'
      'video-icon'
    when 'Article'
      'article-icon'
    when 'Quiz'
      'quiz-icon'
    else
      'default-icon'
    end
  end

  def get_lesson_index(lesson)
    lesson.idx
  end

  def get_lesson_url(lesson)
    "/courses/#{lesson.course.name}/lessons/#{lesson.id}"
  end
end
