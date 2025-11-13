require 'rails_helper'

RSpec.describe Batch, type: :model do
  let(:course) { create(:course, title: 'Test Course') }
  let(:instructor) { create(:user, email: 'mentor@test.com', first_name: 'Test Mentor') }
  let(:batch) { build(:batch, course: course, title: 'Test Batch', instructor: instructor) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(batch).to be_valid
    end

    it 'is invalid without a title' do
      batch.title = nil
      expect(batch).to_not be_valid
    end

    it 'is invalid without a course' do
      batch.course = nil
      expect(batch).to_not be_valid
    end

    it 'generates a slug from title' do
      batch.save!
      expect(batch.name).to eq('test-batch')
    end

    it 'handles duplicate slugs' do
      create(:batch, title: 'Test Batch', course: course)
      batch2 = create(:batch, title: 'Test Batch', course: course)
      expect(batch2.name).to eq('test-batch-2')
    end
  end

  describe 'associations' do
    it 'belongs to course' do
      expect(batch).to respond_to(:course)
    end

    it 'belongs to instructor' do
      expect(batch).to respond_to(:instructor)
    end

    it 'has many batch_enrollments' do
      expect(batch).to respond_to(:batch_enrollments)
    end

    it 'has many students through batch_enrollments' do
      expect(batch).to respond_to(:students)
    end

    it 'has many live_classes' do
      expect(batch).to respond_to(:live_classes)
    end
  end

  describe 'enrollment management' do
    let(:student) { create(:user, email: 'student@test.com') }

    before do
      batch.save!
    end

    it 'allows student enrollment' do
      expect do
        batch.enroll_student(student)
      end.to change(batch.batch_enrollments, :count).by(1)
      
      expect(batch.students).to include(student)
    end

    it 'prevents duplicate enrollments' do
      batch.enroll_student(student)
      
      expect do
        batch.enroll_student(student)
      end.not_to change(batch.batch_enrollments, :count)
    end

    it 'tracks enrollment date' do
      enrollment = batch.enroll_student(student)
      expect(enrollment.created_at).to be_present
    end
  end

  describe '#student_count' do
    before { batch.save! }

    it 'returns correct student count' do
      create_list(:batch_enrollment, 3, batch: batch)
      expect(batch.student_count).to eq(3)
    end

    it 'returns 0 for batch with no students' do
      expect(batch.student_count).to eq(0)
    end
  end

  describe '#is_published?' do
    it 'returns false for unpublished batch' do
      batch.published = false
      expect(batch.is_published?).to be_falsey
    end

    it 'returns true for published batch' do
      batch.published = true
      expect(batch.is_published?).to be_truthy
    end
  end

  describe '#can_enroll?' do
    let(:student) { create(:user) }

    before { batch.save! }

    it 'allows enrollment when batch is published and not full' do
      batch.update(published: true, max_students: 10)
      expect(batch.can_enroll?(student)).to be_truthy
    end

    it 'prevents enrollment when batch is not published' do
      batch.update(published: false)
      expect(batch.can_enroll?(student)).to be_falsey
    end

    it 'prevents enrollment when batch is full' do
      batch.update(published: true, max_students: 2)
      create_list(:batch_enrollment, 2, batch: batch)
      expect(batch.can_enroll?(student)).to be_falsey
    end

    it 'prevents enrollment when student already enrolled' do
      batch.update(published: true)
      batch.enroll_student(student)
      expect(batch.can_enroll?(student)).to be_falsey
    end

    it 'allows enrollment when max_students is nil' do
      batch.update(published: true, max_students: nil)
      create_list(:batch_enrollment, 100, batch: batch)
      expect(batch.can_enroll?(student)).to be_truthy
    end
  end

  describe '#start_date and #end_date' do
    it 'handles date ranges' do
      start_date = 1.month.from_now
      end_date = 3.months.from_now
      
      batch.start_date = start_date
      batch.end_date = end_date
      batch.save!
      
      expect(batch.start_date).to eq(start_date.to_date)
      expect(batch.end_date).to eq(end_date.to_date)
    end

    it 'validates end date is after start date' do
      batch.start_date = 1.month.from_now
      batch.end_date = 1.week.from_now
      
      expect(batch).to_not be_valid
      expect(batch.errors[:end_date]).to be_present
    end
  end

  describe '#is_active?' do
    it 'returns true for batch in session' do
      batch.start_date = 1.week.ago
      batch.end_date = 1.week.from_now
      expect(batch.is_active?).to be_truthy
    end

    it 'returns false for batch not started' do
      batch.start_date = 1.week.from_now
      batch.end_date = 2.weeks.from_now
      expect(batch.is_active?).to be_falsey
    end

    it 'returns false for batch ended' do
      batch.start_date = 2.weeks.ago
      batch.end_date = 1.week.ago
      expect(batch.is_active?).to be_falsey
    end

    it 'returns true when dates are nil' do
      batch.start_date = nil
      batch.end_date = nil
      expect(batch.is_active?).to be_truthy
    end
  end

  describe 'batch creation workflow (matching Frappe test)' do
    # This matches the test_lms_enrollment.py new_course_batch method
    before do
      # Add mentor to course (similar to Frappe test setup)
      course.add_mentor(instructor.email) if course.respond_to?(:add_mentor)
    end

    it 'creates batch with course and mentor' do
      batch_attrs = {
        title: 'Test Batch',
        course: course,
        instructor: instructor
      }
      
      new_batch = Batch.create!(batch_attrs)
      
      expect(new_batch.title).to eq('Test Batch')
      expect(new_batch.course).to eq(course)
      expect(new_batch.instructor).to eq(instructor)
      expect(new_batch.name).to eq('test-batch')
    end

    it 'allows enrollment after creation' do
      batch.save!
      student = create(:user, email: 'test01@test.com', first_name: 'Test')
      
      enrollment = batch.enroll_student(student)
      
      expect(enrollment).to be_persisted
      expect(enrollment.batch).to eq(batch)
      expect(enrollment.user).to eq(student)
    end
  end

  describe 'scopes' do
    before do
      create(:batch, published: true, course: course)
      create(:batch, published: false, course: course)
      create(:batch, published: true, 
             start_date: 1.week.ago, 
             end_date: 1.week.from_now, 
             course: course)
    end

    describe '.published' do
      it 'returns only published batches' do
        published_batches = Batch.published
        expect(published_batches.count).to eq(2)
        expect(published_batches.all?(&:published?)).to be_truthy
      end
    end

    describe '.active' do
      it 'returns only active batches' do
        active_batches = Batch.active
        expect(active_batches.count).to eq(1)
        expect(active_batches.first.is_active?).to be_truthy
      end
    end

    describe '.by_course' do
      let(:other_course) { create(:course) }
      
      before do
        create(:batch, course: other_course)
      end

      it 'returns batches for specific course' do
        course_batches = Batch.by_course(course)
        expect(course_batches.count).to eq(3) # All batches created for course
        expect(course_batches.all? { |b| b.course == course }).to be_truthy
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save' do
      it 'generates slug from title' do
        new_batch = Batch.new(title: 'Advanced Programming Batch', course: course)
        new_batch.save
        expect(new_batch.name).to eq('advanced-programming-batch')
      end

      it 'updates slug when title changes' do
        batch.save!
        batch.update(title: 'Updated Batch Title')
        expect(batch.name).to eq('updated-batch-title')
      end
    end
  end

  after(:each) do
    # Clean up data similar to Frappe tearDown
    BatchEnrollment.where(batch: batch).destroy_all if batch.persisted?
    LiveClass.where(batch: batch).destroy_all if batch.persisted? && defined?(LiveClass)
  end
end