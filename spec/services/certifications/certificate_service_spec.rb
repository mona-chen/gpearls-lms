require 'rails_helper'

RSpec.describe Certifications::CertificateService, type: :service do
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let!(:enrollment) { create(:enrollment, user: user, course: course, completed: true) }

  describe '.create_certificate' do
    context 'successful certificate creation' do
      let(:params) { { course: course.id } }

      it 'creates a certificate for completed course' do
        expect {
          result = described_class.create_certificate(params, user)
          expect(result[:success]).to be_truthy
        }.to change(Certificate, :count).by(1)
      end

      it 'returns success response with certificate data' do
        result = described_class.create_certificate(params, user)

        expect(result[:success]).to be_truthy
        expect(result[:data]).to be_a(Certificate)
        expect(result[:message]).to eq('Certificate created successfully')
      end

      it 'sets default values correctly' do
        result = described_class.create_certificate(params, user)
        certificate = result[:data]

        expect(certificate.name).to include(user.full_name)
        expect(certificate.name).to include(course.title)
        expect(certificate.category).to eq('Course Completion')
        expect(certificate.template).to eq('default')
        expect(certificate.published).to be_truthy
        expect(certificate.expiry_date).to be_within(1.day).of(1.year.from_now.to_date)
      end

      it 'allows custom parameters' do
        custom_params = {
          course: course.id,
          category: 'Advanced Certification',
          template: 'premium',
          expiry_date: '2025-12-31',
          published: false
        }

        result = described_class.create_certificate(custom_params, user)
        certificate = result[:data]

        expect(certificate.category).to eq('Advanced Certification')
        expect(certificate.template).to eq('premium')
        expect(certificate.expiry_date).to eq(Date.parse('2025-12-31'))
        expect(certificate.published).to be_falsey
      end
    end

    context 'validation failures' do
      it 'fails for non-existent user' do
        result = described_class.create_certificate({ course: course.id }, nil)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('User not found')
      end

      it 'fails for missing course parameter' do
        result = described_class.create_certificate({}, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Course is required')
      end

      it 'fails for non-existent course' do
        result = described_class.create_certificate({ course: 99999 }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Course not found')
      end

      it 'fails if user is not enrolled in course' do
        other_course = create(:course)
        result = described_class.create_certificate({ course: other_course.id }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('User is not enrolled in this course')
      end

      it 'fails if course is not completed' do
        enrollment.update(completed: false)
        result = described_class.create_certificate({ course: course.id }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Course not completed')
      end

      it 'returns existing certificate if already created' do
        existing_certificate = create(:certificate, user: user, course: course)

        expect {
          result = described_class.create_certificate({ course: course.id }, user)
          expect(result[:success]).to be_truthy
          expect(result[:data]).to eq(existing_certificate)
          expect(result[:message]).to eq('Certificate already exists')
        }.not_to change(Certificate, :count)
      end
    end

    context 'Frappe API compatibility' do
      it 'returns proper success response format' do
        result = described_class.create_certificate({ course: course.id }, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:data)
        expect(result).to have_key(:message)
        expect(result[:success]).to be_truthy
      end

      it 'returns proper error response format' do
        result = described_class.create_certificate({}, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:error)
        expect(result).to have_key(:message)
        expect(result[:success]).to be_falsey
      end
    end
  end
end
