require 'rails_helper'

RSpec.describe Certifications::CertifiedParticipantsService, type: :service do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:course1) { create(:course) }
  let(:course2) { create(:course) }
  let(:category) { create(:certification_category) }

  let!(:certification1) {
    create(:certification,
           user: user1,
           course: course1,
           category: category,
           status: 'Issued',
           certificate_number: 'CERT-2024-ABCD'
          )
  }

  let!(:certification2) {
    create(:certification,
           user: user2,
           course: course2,
           category: category,
           status: 'Issued',
           certificate_number: 'CERT-2024-EFGH'
          )
  }

  let!(:draft_certification) {
    create(:certification,
           user: user1,
           course: course1,
           status: 'Draft'
          )
  }

  describe '.call' do
    context 'without filters' do
      it 'returns all issued certifications' do
        result = described_class.call

        expect(result).to have_key('data')
        expect(result['data'].length).to eq(2)

        certificate_numbers = result['data'].map { |cert| cert['certificate_number'] }
        expect(certificate_numbers).to include('CERT-2024-ABCD', 'CERT-2024-EFGH')
      end

      it 'excludes non-issued certifications' do
        result = described_class.call

        certificate_numbers = result['data'].map { |cert| cert['certificate_number'] }
        expect(certificate_numbers).not_to include(nil) # Draft certification has no number
      end
    end

    context 'with category filter' do
      let(:other_category) { create(:certification_category, name: 'Other Category') }
      let!(:other_certification) {
        create(:certification,
               user: user1,
               course: course1,
               category: other_category,
               status: 'Issued'
              )
      }

      it 'filters by category name' do
        params = { category: category.name }
        result = described_class.call(params)

        expect(result['data'].length).to eq(2) # Both certifications are in the same category
        categories = result['data'].map { |cert| cert['category'] }.uniq
        expect(categories).to eq([ category.name ])
      end
    end

    context 'with course filter' do
      it 'filters by course title' do
        params = { course: course1.title }
        result = described_class.call(params)

        expect(result['data'].length).to eq(1)
        expect(result['data'].first['course_name']).to eq(course1.title)
      end
    end

    context 'with both filters' do
      it 'applies both category and course filters' do
        params = { category: category.name, course: course1.title }
        result = described_class.call(params)

        expect(result['data'].length).to eq(1)
        cert = result['data'].first
        expect(cert['category']).to eq(category.name)
        expect(cert['course_name']).to eq(course1.title)
      end
    end

    context 'ordering' do
      it 'orders by creation date descending' do
        # Create another certification with earlier date
        earlier_cert = create(:certification,
                             user: user1,
                             course: course1,
                             category: category,
                             status: 'Issued',
                             created_at: 1.day.ago
                            )

        result = described_class.call

        # Should be ordered with most recent first
        first_cert_date = Date.parse(result['data'].first['creation'])
        last_cert_date = Date.parse(result['data'].last['creation'])
        expect(first_cert_date).to be >= last_cert_date
      end
    end

    context 'Frappe API compatibility' do
      it 'returns exact field structure matching Frappe LMS' do
        result = described_class.call
        cert_data = result['data'].first

        expected_fields = [
          'name', 'user', 'user_name', 'course', 'course_name',
          'category', 'evaluator', 'evaluator_name', 'status',
          'certificate_number', 'issued_at', 'creation', 'modified'
        ]

        expected_fields.each do |field|
          expect(cert_data).to have_key(field), "Missing field: #{field}"
        end
      end

      it 'formats dates correctly' do
        result = described_class.call
        cert_data = result['data'].first

        expect(cert_data['issued_at']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(cert_data['creation']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(cert_data['modified']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end

      it 'includes proper user and course information' do
        result = described_class.call
        cert_data = result['data'].first

        expect(cert_data['user']).to eq(user1.email)
        expect(cert_data['user_name']).to eq(user1.full_name)
        expect(cert_data['course_name']).to eq(course1.title)
      end
    end
  end
end
