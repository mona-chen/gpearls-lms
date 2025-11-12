require 'rails_helper'

RSpec.describe Batches::BatchEnrollmentService, type: :service do
  let(:user) { create(:user) }
  let(:batch) { create(:batch, allow_self_enrollment: true, published: true) }
  let(:course) { create(:course) }

  before do
    create(:batch_course, batch: batch, course: course)
  end

  describe '.enroll_in_batch' do
    context 'successful enrollment' do
      it 'creates batch enrollment' do
        result = described_class.enroll_in_batch(batch.name, user)

        expect(result[:success]).to be_truthy
        expect(result[:data]).to be_a(BatchEnrollment)
        expect(result[:message]).to eq('Successfully enrolled in batch')
      end

      it 'creates course enrollments for batch courses' do
        expect {
          described_class.enroll_in_batch(batch.name, user)
        }.to change(Enrollment, :count).by(1)

        enrollment = Enrollment.last
        expect(enrollment.user).to eq(user)
        expect(enrollment.course).to eq(course)
        expect(enrollment.batch).to eq(batch)
      end

      it 'returns success for already enrolled user' do
        create(:batch_enrollment, batch: batch, user: user)

        result = described_class.enroll_in_batch(batch.name, user)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Already enrolled in this batch')
      end
    end

    context 'validation failures' do
      it 'fails for non-existent batch' do
        result = described_class.enroll_in_batch('non-existent', user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Batch not found')
      end

      it 'fails for nil user' do
        result = described_class.enroll_in_batch(batch.name, nil)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('User not found')
      end

      it 'fails for batch not allowing self-enrollment' do
        batch.update(allow_self_enrollment: false)
        result = described_class.enroll_in_batch(batch.name, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include('does not allow self-enrollment')
      end

      it 'fails for unpublished batch' do
        batch.update(published: false)
        result = described_class.enroll_in_batch(batch.name, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include('not published')
      end

      it 'fails for full batch' do
        batch.update(seat_count: 1)
        create(:batch_enrollment, batch: batch) # Fill the batch

        result = described_class.enroll_in_batch(batch.name, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include('full')
      end

      it 'fails for batch not accepting enrollments' do
        batch.update(start_date: 1.month.ago, end_date: 1.week.ago) # Completed batch

        result = described_class.enroll_in_batch(batch.name, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include('not accepting enrollments')
      end
    end

    context 'time conflicts' do
      let(:conflicting_batch) {
        create(:batch,
               allow_self_enrollment: true,
               published: true,
               start_date: batch.start_date,
               end_date: batch.end_date,
               start_time: batch.start_time,
               end_time: batch.end_time
        )
      }

      before do
        create(:batch_enrollment, batch: conflicting_batch, user: user)
      end

      it 'fails when there are time conflicts' do
        result = described_class.enroll_in_batch(batch.name, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include('Time conflicts')
      end
    end

    context 'course conflicts' do
      let(:other_batch) {
        create(:batch, allow_self_enrollment: true, published: true)
      }

      before do
        create(:batch_course, batch: other_batch, course: course)
        create(:batch_enrollment, batch: other_batch, user: user)
      end

      it 'fails when there are course conflicts' do
        result = described_class.enroll_in_batch(batch.name, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include('Already enrolled in same courses')
      end
    end

    context 'email notifications' do
      it 'sends confirmation email' do
        expect {
          described_class.enroll_in_batch(batch.name, user)
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('BatchEnrollmentMailer', 'confirmation_email', 'deliver_later', anything)
      end
    end

    context 'Frappe API compatibility' do
      it 'returns proper success response format' do
        result = described_class.enroll_in_batch(batch.name, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:data)
        expect(result).to have_key(:message)
        expect(result[:success]).to be_truthy
      end

      it 'returns proper error response format' do
        result = described_class.enroll_in_batch('non-existent', user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:error)
        expect(result).to have_key(:message)
        expect(result[:success]).to be_falsey
      end
    end
  end
end
