require 'rails_helper'

RSpec.describe Payments::PaymentLinkService, type: :service do
  let(:user) { create(:user) }
  let(:course) { create(:course, course_price: 100.0, currency: 'USD') }
  let(:batch) { create(:batch, paid_batch: true, amount: 50.0, currency: 'USD') }
  let(:program) { create(:lms_program) }

  before do
    # Create a payment gateway for testing
    create(:payment_gateway, gateway_type: 'paystack', status: 'active', is_primary: true)
  end

  describe '.call' do
    context 'successful payment link generation for course' do
      let(:params) { { item_type: 'course', item_id: course.id } }

      it 'creates payment and returns payment link' do
        allow_any_instance_of(Payment).to receive(:initialize_payment).and_return({
          'authorization_url' => 'https://paystack.com/pay/test',
          'reference' => 'test_ref_123',
          'access_code' => 'test_access_code'
        })

        result = described_class.call(params, user)

        expect(result[:success]).to be_truthy
        expect(result[:data][:payment]).to be_a(Hash)
        expect(result[:data][:payment_link]).to be_a(Hash)
        expect(result[:data][:payment_link][:payment_url]).to eq('https://paystack.com/pay/test')
        expect(result[:data][:message]).to eq('Payment link generated successfully')
      end

      it 'creates payment record with correct details' do
        allow_any_instance_of(Payment).to receive(:initialize_payment).and_return({})

        expect {
          described_class.call(params, user)
        }.to change(Payment, :count).by(1)

        payment = Payment.last
        expect(payment.user).to eq(user)
        expect(payment.course).to eq(course)
        expect(payment.amount).to eq(100.0)
        expect(payment.currency).to eq('USD')
        expect(payment.payment_method).to eq('paystack')
        expect(payment.payment_status).to eq('Pending')
      end
    end

    context 'successful payment link generation for batch' do
      let(:params) { { item_type: 'batch', item_id: batch.id } }

      it 'creates payment for batch' do
        allow_any_instance_of(Payment).to receive(:initialize_payment).and_return({})

        result = described_class.call(params, user)

        expect(result[:success]).to be_truthy
        payment = Payment.last
        expect(payment.batch).to eq(batch)
        expect(payment.amount).to eq(50.0)
      end
    end

    context 'user already has access' do
      let(:params) { { item_type: 'course', item_id: course.id } }

      before do
        create(:enrollment, user: user, course: course)
      end

      it 'returns error when user already has access' do
        result = described_class.call(params, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('You already have access to this item')
      end
    end

    context 'existing pending payment' do
      let(:params) { { item_type: 'course', item_id: course.id } }

      before do
        create(:payment, user: user, course: course, payment_status: 'Pending')
      end

      it 'returns existing payment when pending payment exists' do
        result = described_class.call(params, user)

        expect(result[:success]).to be_truthy
        expect(result[:data][:message]).to eq('Existing payment found')
        expect(result[:data][:payment][:user]).to eq(user.email)
      end
    end

    context 'validation failures' do
      it 'fails for nil user' do
        result = described_class.call({ item_type: 'course', item_id: course.id }, nil)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('User not found')
      end

      it 'fails for missing item_type' do
        result = described_class.call({ item_id: course.id }, user)

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

      it 'fails for invalid item_type' do
        result = described_class.call({ item_type: 'invalid', item_id: course.id }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Item not found')
      end
    end

    context 'gateway integration' do
      let(:params) { { item_type: 'course', item_id: course.id, gateway: 'razorpay' } }

      it 'uses specified gateway' do
        allow_any_instance_of(Payment).to receive(:initialize_payment).and_return({})

        result = described_class.call(params, user)

        expect(result[:success]).to be_truthy
        payment = Payment.last
        expect(payment.payment_method).to eq('razorpay')
      end
    end

    context 'Frappe API compatibility' do
      it 'returns proper success response format' do
        allow_any_instance_of(Payment).to receive(:initialize_payment).and_return({})

        result = described_class.call({ item_type: 'course', item_id: course.id }, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:data)
        expect(result[:success]).to be_truthy
        expect(result[:data]).to have_key(:payment)
        expect(result[:data]).to have_key(:payment_link)
        expect(result[:data]).to have_key(:message)
      end

      it 'returns proper error response format' do
        result = described_class.call({}, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:error)
        expect(result[:success]).to be_falsey
      end
    end
  end
end
