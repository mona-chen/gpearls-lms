require 'rails_helper'

RSpec.describe Batches::BatchesService, type: :service do
  let(:instructor) { create(:user, :instructor) }
  let(:course) { create(:course, instructor: instructor) }
  let!(:batch) { create(:batch, instructor: instructor) }
  let!(:batch_course) { create(:batch_course, batch: batch, course: course) }

  describe '.call' do
    context 'without filters' do
      it 'returns all published batches with Frappe-compatible format' do
        result = described_class.call

        expect(result).to have_key('data')
        expect(result['data']).to be_an(Array)
        expect(result['data'].first).to include(
          'name' => batch.name,
          'title' => batch.title,
          'batch_id' => batch.id,
          'published' => batch.published,
          'allow_self_enrollment' => batch.allow_self_enrollment,
          'certification' => batch.certification,
          'paid_batch' => batch.paid_batch,
          'status' => batch.status,
          'current_seats' => batch.current_seats,
          'seats_left' => batch.seats_left,
          'full' => batch.full?,
          'accept_enrollments' => batch.accept_enrollments?
        )
      end

      it 'includes course information' do
        result = described_class.call

        batch_data = result['data'].first
        expect(batch_data['course_id']).to eq(course.id)
        expect(batch_data['course_title']).to eq(course.title)
        expect(batch_data['courses']).to be_an(Array)
      end

      it 'includes proper timestamps' do
        result = described_class.call

        batch_data = result['data'].first
        expect(batch_data['creation']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(batch_data['modified']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end
    end

    context 'with filters' do
      let!(:unpublished_batch) { create(:batch, published: false) }

      it 'filters by published status' do
        params = { filters: { 'published' => 1 } }
        result = described_class.call(params)

        expect(result['data'].length).to eq(1)
        expect(result['data'].first['published']).to be_truthy
      end

      it 'filters by start_date' do
        future_batch = create(:batch, start_date: 1.month.from_now)
        params = { filters: { 'start_date' => [ '>=', Date.today.to_s ] } }
        result = described_class.call(params)

        expect(result['data'].length).to eq(2) # batch and future_batch
      end
    end

    context 'with pagination' do
      let!(:batch2) { create(:batch, instructor: instructor) }

      it 'applies limit' do
        params = { limit: 1 }
        result = described_class.call(params)

        expect(result['data'].length).to eq(1)
      end

      it 'applies offset' do
        params = { start: 1, limit: 1 }
        result = described_class.call(params)

        expect(result['data'].length).to eq(1)
      end
    end

    context 'with ordering' do
      let!(:older_batch) { create(:batch, start_date: 1.month.ago) }

      it 'orders by start_date desc by default' do
        result = described_class.call

        expect(result['data'].first['batch_id']).to eq(batch.id) # Most recent first
      end

      it 'orders by custom field' do
        params = { order_by: 'title ASC' }
        result = described_class.call(params)

        expect(result).to have_key('data')
      end
    end

    context 'Frappe API compatibility' do
      it 'returns exact field names matching Frappe LMS' do
        result = described_class.call
        batch_data = result['data'].first

        expected_fields = [
          'name', 'title', 'batch_id', 'course_id', 'course_title',
          'start_date', 'end_date', 'start_time', 'end_time', 'timezone',
          'description', 'batch_details', 'published', 'allow_self_enrollment',
          'certification', 'seat_count', 'evaluation_end_date', 'medium',
          'category', 'confirmation_email_template', 'instructors', 'zoom_account',
          'paid_batch', 'amount', 'currency', 'amount_usd', 'show_live_class',
          'allow_future', 'status', 'current_seats', 'seats_left', 'full',
          'accept_enrollments', 'courses', 'creation', 'modified', 'owner'
        ]

        expected_fields.each do |field|
          expect(batch_data).to have_key(field), "Missing field: #{field}"
        end
      end

      it 'formats dates correctly' do
        result = described_class.call
        batch_data = result['data'].first

        expect(batch_data['start_date']).to match(/\d{4}-\d{2}-\d{2}/)
        expect(batch_data['end_date']).to match(/\d{4}-\d{2}-\d{2}/)
        expect(batch_data['start_time']).to match(/\d{2}:\d{2}:\d{2}/)
        expect(batch_data['end_time']).to match(/\d{2}:\d{2}:\d{2}/)
      end
    end
  end
end
