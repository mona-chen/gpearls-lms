require 'rails_helper'

RSpec.describe Payments::OrderSummaryService, type: :service do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:course) { create(:course) }
  let!(:payment) { create(:payment, user: user, course: course, payment_status: 'Completed') }

  describe '.call' do
    context 'with valid payment and authorized user' do
      it 'returns complete order summary' do
        result = described_class.call(payment.name, user)

        expect(result[:success]).to be_truthy
        expect(result[:data]).to be_a(Hash)

        order_data = result[:data]
        expect(order_data[:order_id]).to eq(payment.name)
        expect(order_data[:payment_id]).to eq(payment.id)
        expect(order_data[:user]).to eq(user.full_name)
        expect(order_data[:user_email]).to eq(user.email)
        expect(order_data[:item_type]).to eq('course')
        expect(order_data[:item_name]).to eq(course.title)
        expect(order_data[:amount]).to eq(payment.amount)
        expect(order_data[:currency]).to eq(payment.currency)
        expect(order_data[:payment_status]).to eq('Completed')
      end

      it 'includes payment logs' do
        create(:payment_log, payment: payment, event_type: 'payment_completed', status: 'success')

        result = described_class.call(payment.name, user)

        expect(result[:data][:payment_logs]).to be_an(Array)
        expect(result[:data][:payment_logs].length).to eq(1)
      end
    end

    context 'with invalid payment ID' do
      it 'returns error for non-existent payment' do
        result = described_class.call('non-existent-payment', user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Payment not found')
      end
    end

    context 'with unauthorized user' do
      it 'returns access denied error' do
        result = described_class.call(payment.name, other_user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Access denied')
      end
    end

    context 'with nil user' do
      it 'returns user not found error' do
        result = described_class.call(payment.name, nil)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('User not found')
      end
    end

    context 'item type detection' do
      let(:batch) { create(:batch) }
      let(:program) { create(:lms_program) }

      it 'correctly identifies course payments' do
        course_payment = create(:payment, user: user, course: course)
        result = described_class.call(course_payment.name, user)

        expect(result[:data][:item_type]).to eq('course')
        expect(result[:data][:item_name]).to eq(course.title)
      end

      it 'correctly identifies batch payments' do
        batch_payment = create(:payment, user: user, batch: batch)
        result = described_class.call(batch_payment.name, user)

        expect(result[:data][:item_type]).to eq('batch')
        expect(result[:data][:item_name]).to eq(batch.title)
      end

      it 'correctly identifies program payments' do
        program_payment = create(:payment, user: user, program: program)
        result = described_class.call(program_payment.name, user)

        expect(result[:data][:item_type]).to eq('program')
        expect(result[:data][:item_name]).to eq(program.title)
      end
    end

    context 'Frappe API compatibility' do
      it 'returns proper success response format' do
        result = described_class.call(payment.name, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:data)
        expect(result[:success]).to be_truthy
      end

      it 'returns proper error response format' do
        result = described_class.call('non-existent', user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:error)
        expect(result[:success]).to be_falsey
      end
    end
  end
end
