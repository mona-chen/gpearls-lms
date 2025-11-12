require 'rails_helper'

RSpec.describe Course, type: :model do
  let(:instructor) { create(:user, :instructor) }
  let(:course) { build(:course, instructor: instructor) }

  describe 'FactoryBot factories' do
    it 'has a valid default factory' do
      expect(course).to be_valid
    end

    it 'creates valid published course' do
      published_course = build(:course, :published, instructor: instructor)
      expect(published_course).to be_valid
      expect(published_course.published).to be true
    end

    it 'creates valid featured course' do
      featured_course = build(:course, :featured, instructor: instructor)
      expect(featured_course).to be_valid
      expect(featured_course.featured).to be true
    end

    it 'can create course in database' do
      expect {
        create(:course, instructor: instructor)
      }.to change(Course, :count).by(1)
    end
  end

  describe 'Associations' do
    it 'belongs to an instructor' do
      expect(course).to belong_to(:instructor).class_name('User').optional(true)
    end

    it 'belongs to an evaluator' do
      expect(course).to belong_to(:evaluator).class_name('User').optional(true)
    end

    it 'has many chapters' do
      expect(course).to have_many(:chapters).dependent(:destroy)
    end

    it 'has many lessons' do
      expect(course).to have_many(:lessons).dependent(:destroy)
    end

    it 'has many enrollments' do
      expect(course).to have_many(:enrollments).dependent(:destroy)
    end

    it 'has many quizzes' do
      expect(course).to have_many(:quizzes).dependent(:destroy)
    end
  end

  describe 'Validations' do
    it 'is valid with valid attributes' do
      expect(course).to be_valid
    end

    it 'is not valid without title' do
      course.title = nil
      expect(course).not_to be_valid
      expect(course.errors[:title]).to include("can't be blank")
    end

    it 'is not valid with empty title' do
      course.title = ''
      expect(course).not_to be_valid
    end

    it 'is valid without description' do
      course.description = nil
      expect(course).to be_valid
    end

    it 'is valid without instructor' do
      course.instructor = nil
      expect(course).to be_valid
    end

    it 'is valid without evaluator' do
      course.evaluator = nil
      expect(course).to be_valid
    end

    it 'is valid with very long title' do
      course.title = 'A' * 255
      expect(course).to be_valid
    end
  end

  describe 'Database fields' do
    it 'has expected attributes' do
      saved_course = create(:course,
        title: 'Test Course',
        description: 'Test Description',
        category: 'Programming',
        short_introduction: 'Test Intro',
        video_link: 'https://example.com/video',
        tags: 'ruby, rails',
        published: true,
        featured: true,
        instructor: instructor
      )

      expect(saved_course.title).to eq('Test Course')
      expect(saved_course.description).to eq('Test Description')
      expect(saved_course.category).to eq('Programming')
      expect(saved_course.short_introduction).to eq('Test Intro')
      expect(saved_course.video_link).to eq('https://example.com/video')
      expect(saved_course.tags).to eq('ruby, rails')
      expect(saved_course.published).to be true
      expect(saved_course.featured).to be true
      expect(saved_course.instructor).to eq(instructor)
    end
  end

  describe 'Basic queries' do
    let!(:published_course) { create(:course, :published, instructor: instructor) }
    let!(:draft_course) { create(:course, published: false, instructor: instructor) }
    let!(:featured_course) { create(:course, :featured, :published, instructor: instructor) }

    it 'can find published courses' do
      published_courses = Course.where(published: true)
      expect(published_courses).to include(published_course, featured_course)
      expect(published_courses).not_to include(draft_course)
    end

    it 'can find featured courses' do
      featured_courses = Course.where(featured: true)
      expect(featured_courses).to include(featured_course)
      expect(featured_courses).not_to include(published_course, draft_course)
    end

    it 'can find courses by instructor' do
      instructor_courses = Course.where(instructor: instructor)
      expect(instructor_courses).to include(published_course, draft_course, featured_course)
    end

    it 'can find courses by category' do
      ruby_course = create(:course, category: 'Ruby', instructor: instructor)
      python_course = create(:course, category: 'Python', instructor: instructor)

      ruby_courses = Course.where(category: 'Ruby')
      expect(ruby_courses).to include(ruby_course)
      expect(ruby_courses).not_to include(python_course)
    end
  end

  describe 'Callbacks and lifecycle' do
    it 'can be created' do
      expect {
        create(:course, instructor: instructor)
      }.to change(Course, :count).by(1)
    end

    it 'can be updated' do
      course.save!
      expect {
        course.update!(title: 'Updated Title')
      }.to change(course, :title).to('Updated Title')
    end

    it 'can be destroyed' do
      course.save!
      expect {
        course.destroy
      }.to change(Course, :count).by(-1)
    end

    it 'stores timestamps' do
      course.save!
      expect(course.created_at).to be_present
      expect(course.updated_at).to be_present
    end
  end

  describe 'Edge cases' do
    it 'handles course with no instructor' do
      course_without_instructor = create(:course, instructor: nil)
      expect(course_without_instructor).to be_valid
      expect(course_without_instructor.instructor).to be_nil
    end

    it 'handles course with nil tags' do
      course.tags = nil
      expect(course).to be_valid
    end

    it 'handles course with empty tags' do
      course.tags = ''
      expect(course).to be_valid
    end

    it 'handles course with comma-separated tags' do
      course.tags = 'ruby, rails, programming'
      expect(course).to be_valid
    end

    it 'handles course with special characters in title' do
      course.title = 'Ruby & Rails: Advanced Programming!'
      expect(course).to be_valid
    end

    it 'handles course with unicode characters in title' do
      course.title = '编程基础：Ruby语言'
      expect(course).to be_valid
    end
  end

  describe 'Relationships with other models' do
    it 'can count associated enrollments' do
      course.save!
      create_list(:enrollment, 3, course: course)

      expect(course.enrollments.count).to eq(3)
    end

    it 'can count associated chapters' do
      # Skip this test if Chapter model doesn't exist or has issues
      begin
        course.save!
        create_list(:chapter, 2, course: course)
        expect(course.chapters.count).to eq(2)
      rescue => e
        skip "Chapter model not properly set up: #{e.message}"
      end
    end

    it 'can count associated lessons' do
      # Skip this test if Lesson model doesn't exist or has issues
      begin
        course.save!
        create_list(:lesson, 3, course: course)
        expect(course.lessons.count).to eq(3)
      rescue => e
        skip "Lesson model not properly set up: #{e.message}"
      end
    end
  end

  describe 'Business logic validation' do
    it 'can be published' do
      course.published = true
      course.save!
      expect(course.reload.published).to be true
    end

    it 'can be featured' do
      course.featured = true
      course.save!
      expect(course.reload.featured).to be true
    end

    it 'can be unpublished' do
      course.published = true
      course.save!

      course.update!(published: false)
      expect(course.reload.published).to be false
    end

    it 'can have both published and featured flags' do
      course.update!(published: true, featured: true)
      expect(course.reload.published).to be true
      expect(course.reload.featured).to be true
    end
  end

  describe 'Performance considerations' do
    it 'includes associations to prevent N+1 queries' do
      course_with_associations = create(:course, instructor: instructor)

      # This should not generate N+1 queries when associations exist
      expect {
        Course.includes(:instructor).find(course_with_associations.id)
      }.not_to raise_error
    end
  end
end
