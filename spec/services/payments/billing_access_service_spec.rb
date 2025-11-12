require 'rails_helper'

RSpec.describe Payments::BillingAccessService, type: :service do
  let(:user) { create(:user) }
  let(:paid_course) { create(:course, course_price: 100.0, currency: 'USD') }
  let(:free_course) { create(:course, course_price: 0.0) }
  let(:paid_batch) { create(:batch, paid_batch: true, amount: 50.0, currency: 'USD') }
  let(:free_batch) { create(:batch, paid_batch: false) }
  let(:paid_program) { create(:lms_program) }

  describe '.call' do
    context 'course access validation' do
      context 'paid course' do
        let(:params) { { item_type: 'course', item_id: paid_course.id } }

        it 'returns payment required when user has no access' do
          result = described_class.call(params, user)

          expect(result[:success]).to be_truthy
          access_data = result[:data]
          expect(access_data[:has_access]).to be_falsey
          expect(access_data[:is_paid]).to be_truthy
          expect(access_data[:payment_required]).to be_truthy
          expect(access_data[:item_name]).to eq(paid_course.title)
        end

        it 'includes pricing information for paid courses' do
          result = described_class.call(params, user)

          pricing = result[:data]
          expect(pricing[:price]).to eq(100.0)
          expect(pricing[:currency]).to eq('USD')
        end

        it 'returns access granted when user has enrollment' do
          create(:enrollment, user: user, course: paid_course)

          result = described_class.call(params, user)

          access_data = result[:data]
          expect(access_data[:has_access]).to be_truthy
          expect(access_data[:payment_required]).to be_falsey
          expect(access_data[:access_granted_at]).to be_present
        end
      end

      context 'free course' do
        let(:params) { { item_type: 'course', item_id: free_course.id } }

        it 'returns no payment required for free courses' do
          result = described_class.call(params, user)

          access_data = result[:data]
          expect(access_data[:is_paid]).to be_falsey
          expect(access_data[:payment_required]).to be_falsey
        end
      end
    end

    context 'batch access validation' do
      context 'paid batch' do
        let(:params) { { item_type: 'batch', item_id: paid_batch.id } }

        it 'returns payment required when user has no access' do
          result = described_class.call(params, user)

          access_data = result[:data]
          expect(access_data[:has_access]).to be_falsey
          expect(access_data[:is_paid]).to be_truthy
          expect(access_data[:payment_required]).to be_truthy
        end

        it 'returns access granted when user has enrollment' do
          create(:batch_enrollment, user: user, batch: paid_batch)

          result = described_class.call(params, user)

          access_data = result[:data]
          expect(access_data[:has_access]).to be_truthy
          expect(access_data[:payment_required]).to be_falsey
        end
      end

      context 'free batch' do
        let(:params) { { item_type: 'batch', item_id: free_batch.id } }

        it 'returns no payment required for free batches' do
          result = described_class.call(params, user)

          access_data = result[:data]
          expect(access_data[:is_paid]).to be_falsey
          expect(access_data[:payment_required]).to be_falsey
        end
      end
    end

    context 'program access validation' do
      let(:params) { { item_type: 'program', item_id: paid_program.id } }

      it 'returns payment required when user has no access' do
        result = described_class.call(params, user)

        access_data = result[:data]
        expect(access_data[:has_access]).to be_falsey
        expect(access_data[:payment_required]).to be_truthy
      end

      it 'returns access granted when user has membership' do
        create(:lms_program_member, user: user, lms_program: paid_program)

        result = described_class.call(params, user)

        access_data = result[:data]
        expect(access_data[:has_access]).to be_truthy
        expect(access_data[:payment_required]).to be_falsey
      end
    end

    context 'payment status tracking' do
      let(:params) { { item_type: 'course', item_id: paid_course.id } }

      it 'includes payment status when payment exists' do
        create(:payment, user: user, course: paid_course, payment_status: 'Completed')

        result = described_class.call(params, user)

        expect(result[:data][:payment_status]).to eq('Completed')
      end

      it 'returns nil payment status when no payment exists' do
        result = described_class.call(params, user)

        expect(result[:data][:payment_status]).to be_nil
      end
    end

    context 'validation failures' do
      it 'fails for nil user' do
        result = described_class.call({ item_type: 'course', item_id: paid_course.id }, nil)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('User not found')
      end

      it 'fails for missing item_type' do
        result = described_class.call({ item_id: paid_course.id }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Item type is required')
      end

      it 'fails for missing item_id' do
        result = described_class.call({ item_type: 'course' }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Item ID is required')
      end

      it 'fails for non-existent item' do
        result = described_class.call({ item_type: 'course', item_id: 99999 }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Item not found')
      end
    end

    context 'Frappe API compatibility' do
      it 'returns proper success response format' do
        result = described_class.call({ item_type: 'course', item_id: paid_course.id }, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:data)
        expect(result[:success]).to be_truthy
      end

      it 'returns proper error response format' do
        result = described_class.call({}, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:error)
        expect(result[:success]).to be_falsey
      end

      it 'includes all required access fields' do
        result = described_class.call({ item_type: 'course', item_id: paid_course.id }, user)

        access_data = result[:data]
        expected_fields = [
          :item_type, :item_id, :item_name, :has_access, :is_paid,
          :payment_required, :access_granted_at, :payment_status
        ]

        expected_fields.each do |field|
          expect(access_data).to have_key(field), "Missing field: #{field}"
        end
      end
    end
  end
end
