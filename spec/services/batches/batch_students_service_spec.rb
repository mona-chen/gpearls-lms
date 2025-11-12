require 'rails_helper'

RSpec.describe Batches::BatchStudentsService, type: :service do
  let(:batch) { create(:batch) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let!(:enrollment1) { create(:batch_enrollment, batch: batch, user: user1) }
  let!(:enrollment2) { create(:batch_enrollment, batch: batch, user: user2) }

  describe '.call' do
    context 'with valid batch' do
      it 'returns all enrolled students with Frappe-compatible format' do
        result = described_class.call(batch.name)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)

        student_data = result.first
        expect(student_data).to have_key('user_details')
        expect(student_data).to have_key('progress')
        expect(student_data).to have_key('certificates')
        expect(student_data).to have_key('last_activity')
      end

      it 'includes user details' do
        result = described_class.call(batch.name)

        user_details = result.first['user_details']
        expect(user_details).to include(
          'email' => user1.email,
          'name' => user1.full_name,
          'username' => user1.username,
          'user_image' => user1.user_image
        )
      end

      it 'includes enrollment information' do
        result = described_class.call(batch.name)

        enrollment_data = result.first
        expect(enrollment_data).to have_key('member')
        expect(enrollment_data).to have_key('member_name')
        expect(enrollment_data).to have_key('member_username')
        expect(enrollment_data).to have_key('batch')
        expect(enrollment_data).to have_key('status')
      end
    end

    context 'with status filter' do
      let(:completed_batch) { create(:batch, end_date: 1.month.ago) }
      let!(:completed_enrollment) { create(:batch_enrollment, batch: completed_batch, user: user1) }

      it 'filters by active status' do
        result = described_class.call(batch.name, 'active')

        expect(result.length).to eq(2) # Both enrollments are active
        statuses = result.map { |student| student['status'] }
        expect(statuses).to all(eq('Active'))
      end

      it 'filters by completed status' do
        result = described_class.call(completed_batch.name, 'completed')

        expect(result.length).to eq(1)
        expect(result.first['status']).to eq('Completed')
      end

      it 'filters by upcoming status' do
        future_batch = create(:batch, start_date: 1.month.from_now)
        create(:batch_enrollment, batch: future_batch, user: user1)

        result = described_class.call(future_batch.name, 'upcoming')

        expect(result.length).to eq(1)
        expect(result.first['status']).to eq('Upcoming')
      end
    end

    context 'with progress calculation' do
      let(:course) { create(:course) }
      let(:chapter) { create(:chapter, course: course) }
      let(:lesson) { create(:lesson, chapter: chapter) }

      before do
        create(:batch_course, batch: batch, course: course)
        create(:enrollment, user: user1, course: course)
        create(:lesson_progress, user: user1, lesson: lesson, status: 'Complete')
      end

      it 'calculates user progress correctly' do
        result = described_class.call(batch.name)

        user1_data = result.find { |student| student['user_details']['email'] == user1.email }
        expect(user1_data['progress']).to eq(100.0) # 1 completed out of 1 lesson
      end

      it 'includes last activity timestamp' do
        result = described_class.call(batch.name)

        user1_data = result.find { |student| student['user_details']['email'] == user1.email }
        expect(user1_data['last_activity']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end
    end

    context 'with certificates' do
      let!(:certificate) { create(:certificate, user: user1, batch: batch, published: true) }

      it 'includes certificate count' do
        result = described_class.call(batch.name)

        user1_data = result.find { |student| student['user_details']['email'] == user1.email }
        expect(user1_data['certificates']).to eq(1)
      end
    end

    context 'with invalid batch' do
      it 'returns empty array for non-existent batch' do
        result = described_class.call('non-existent-batch')

        expect(result).to eq([])
      end
    end

    context 'Frappe API compatibility' do
      it 'returns exact field structure matching Frappe LMS' do
        result = described_class.call(batch.name)
        student_data = result.first

        expected_fields = [
          'name', 'member', 'member_name', 'member_username', 'batch',
          'batch_name', 'payment', 'source', 'confirmation_email_sent',
          'status', 'enrolled_at', 'completed_at', 'creation', 'modified',
          'user_details', 'progress', 'certificates', 'last_activity'
        ]

        expected_fields.each do |field|
          expect(student_data).to have_key(field), "Missing field: #{field}"
        end
      end

      it 'formats dates correctly' do
        result = described_class.call(batch.name)
        student_data = result.first

        expect(student_data['enrolled_at']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(student_data['creation']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(student_data['modified']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end
    end
  end
end
