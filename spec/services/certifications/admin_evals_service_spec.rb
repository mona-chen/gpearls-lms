require 'rails_helper'

RSpec.describe Certifications::AdminEvalsService, type: :service do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:evaluator) { create(:user, :instructor) }
  let(:course1) { create(:course) }
  let(:course2) { create(:course) }

  let!(:under_review_cert) {
    create(:certification,
           user: user1,
           course: course1,
           evaluator: evaluator,
           status: 'Under Review'
          )
  }

  let!(:submitted_cert) {
    create(:certification,
           user: user2,
           course: course2,
           evaluator: evaluator,
           status: 'Submitted'
          )
  }

  let!(:approved_cert) {
    create(:certification,
           user: user1,
           course: course1,
           status: 'Approved'
          )
  }

  let!(:issued_cert) {
    create(:certification,
           user: user2,
           course: course2,
           status: 'Issued'
          )
  }

  describe '.call' do
    context 'without filters' do
      it 'returns certifications needing admin evaluation' do
        result = described_class.call

        expect(result).to have_key('data')
        expect(result['data'].length).to eq(2)

        statuses = result['data'].map { |cert| cert['status'] }
        expect(statuses).to include('Under Review', 'Submitted')
        expect(statuses).not_to include('Approved', 'Issued')
      end

      it 'orders by creation date descending' do
        result = described_class.call

        # Should be ordered with most recent first
        first_cert_date = Date.parse(result['data'].first['creation'])
        last_cert_date = Date.parse(result['data'].last['creation'])
        expect(first_cert_date).to be >= last_cert_date
      end

      it 'includes evaluation details' do
        result = described_class.call
        eval_data = result['data'].first

        expect(eval_data).to have_key('evaluation_details')
        details = eval_data['evaluation_details']
        expect(details).to have_key('submitted_at')
        expect(details).to have_key('last_modified')
        expect(details).to have_key('days_pending')
      end
    end

    context 'with status filter' do
      it 'filters by specific status' do
        params = { status: 'Under Review' }
        result = described_class.call(params)

        expect(result['data'].length).to eq(1)
        expect(result['data'].first['status']).to eq('Under Review')
      end
    end

    context 'with evaluator filter' do
      let!(:other_evaluator_cert) {
        create(:certification,
               user: user1,
               course: course1,
               evaluator: create(:user, :instructor),
               status: 'Under Review'
              )
      }

      it 'filters by evaluator' do
        params = { evaluator: evaluator.id }
        result = described_class.call(params)

        expect(result['data'].length).to eq(2) # Both under review and submitted have this evaluator
        evaluators = result['data'].map { |cert| cert['evaluator'] }.uniq
        expect(evaluators).to eq([ evaluator.email ])
      end
    end

    context 'with course filter' do
      it 'filters by course' do
        params = { course: course1.id }
        result = described_class.call(params)

        expect(result['data'].length).to eq(1)
        expect(result['data'].first['course']).to eq(course1.id)
      end
    end

    context 'evaluation details' do
      it 'calculates days pending correctly' do
        # Create a certification from 5 days ago
        old_cert = create(:certification,
                         user: user1,
                         course: course1,
                         status: 'Under Review',
                         created_at: 5.days.ago
                        )

        result = described_class.call
        old_cert_data = result['data'].find { |cert| cert['name'] == old_cert.id.to_s }

        expect(old_cert_data['evaluation_details']['days_pending']).to eq(5)
      end

      it 'includes proper timestamps' do
        result = described_class.call
        eval_data = result['data'].first

        details = eval_data['evaluation_details']
        expect(details['submitted_at']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(details['last_modified']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end
    end

    context 'Frappe API compatibility' do
      it 'returns exact field structure matching Frappe LMS' do
        result = described_class.call
        cert_data = result['data'].first

        expected_fields = [
          'name', 'user', 'user_name', 'course', 'course_name',
          'category', 'evaluator', 'evaluator_name', 'status',
          'certificate_number', 'issued_at', 'creation', 'modified',
          'evaluation_details'
        ]

        expected_fields.each do |field|
          expect(cert_data).to have_key(field), "Missing field: #{field}"
        end
      end

      it 'includes evaluation details with correct structure' do
        result = described_class.call
        cert_data = result['data'].first

        details = cert_data['evaluation_details']
        expected_detail_fields = [ 'submitted_at', 'last_modified', 'days_pending' ]

        expected_detail_fields.each do |field|
          expect(details).to have_key(field), "Missing evaluation detail field: #{field}"
        end
      end
    end
  end
end
