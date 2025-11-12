require 'rails_helper'

RSpec.describe Batches::MyBatchesService, type: :service do
  let(:user) { create(:user) }
  let(:instructor) { create(:user, :instructor) }
  let(:batch) { create(:batch, instructor: instructor) }
  let!(:enrollment) { create(:batch_enrollment, user: user, batch: batch) }

  describe '.call' do
    context 'with enrolled user' do
      it 'returns user enrolled batches with Frappe-compatible format' do
        result = described_class.call(user)

        expect(result).to be_an(Array)
        expect(result.length).to eq(1)

        batch_data = result.first
        expect(batch_data).to include(
          'name' => batch.id,
          'title' => batch.title,
          'description' => batch.description,
          'start_date' => batch.start_date&.strftime('%Y-%m-%d'),
          'end_date' => batch.end_date&.strftime('%Y-%m-%d'),
          'published' => batch.published
        )
      end

      it 'includes enrollment information' do
        result = described_class.call(user)

        enrollment_data = result.first['enrollment']
        expect(enrollment_data).to include(
          'name' => enrollment.id,
          'batch' => enrollment.batch_id,
          'member' => enrollment.user_id,
          'enrolled_at' => enrollment.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          'status' => enrollment.status
        )
      end
    end

    context 'with user not enrolled in any batches' do
      let(:other_user) { create(:user) }

      it 'returns empty array' do
        result = described_class.call(other_user)

        expect(result).to eq([])
      end
    end

    context 'with nil user' do
      it 'returns empty array' do
        result = described_class.call(nil)

        expect(result).to eq([])
      end
    end

    context 'multiple enrollments' do
      let(:batch2) { create(:batch, instructor: instructor) }
      let!(:enrollment2) { create(:batch_enrollment, user: user, batch: batch2) }

      it 'returns all enrolled batches' do
        result = described_class.call(user)

        expect(result.length).to eq(2)
        batch_ids = result.map { |b| b['name'] }
        expect(batch_ids).to include(batch.id, batch2.id)
      end
    end

    context 'Frappe API compatibility' do
      it 'returns exact field structure matching Frappe LMS' do
        result = described_class.call(user)
        batch_data = result.first

        expected_fields = [
          'name', 'title', 'description', 'start_date', 'end_date',
          'published', 'enrollment'
        ]

        expected_fields.each do |field|
          expect(batch_data).to have_key(field), "Missing field: #{field}"
        end

        enrollment_fields = [ 'name', 'batch', 'member', 'enrolled_at', 'status' ]
        enrollment_fields.each do |field|
          expect(batch_data['enrollment']).to have_key(field), "Missing enrollment field: #{field}"
        end
      end

      it 'formats dates correctly' do
        result = described_class.call(user)

        expect(result.first['start_date']).to match(/\d{4}-\d{2}-\d{2}/)
        expect(result.first['end_date']).to match(/\d{4}-\d{2}-\d{2}/)
        expect(result.first['enrollment']['enrolled_at']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end
    end
  end
end
