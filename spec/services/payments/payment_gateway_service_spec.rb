require 'rails_helper'

RSpec.describe Payments::PaymentGatewayService, type: :service do
  let!(:active_gateway) {
    create(:payment_gateway,
           name: 'Paystack',
           gateway_type: 'paystack',
           status: 'active',
           is_primary: true,
           settings: {
             'supported_currencies' => [ 'USD', 'NGN', 'EUR' ],
             'fees' => { 'base' => 10, 'percentage' => 1.5 }
           }
          )
  }

  let!(:inactive_gateway) {
    create(:payment_gateway,
           name: 'Stripe',
           gateway_type: 'stripe',
           status: 'inactive'
          )
  }

  let!(:payment1) { create(:payment, payment_gateway: active_gateway, payment_status: 'Completed', amount: 100.0) }
  let!(:payment2) { create(:payment, payment_gateway: active_gateway, payment_status: 'Failed', amount: 50.0) }
  let!(:payment3) { create(:payment, payment_gateway: active_gateway, payment_status: 'Completed', amount: 75.0) }

  describe '.call' do
    it 'returns only active gateways' do
      result = described_class.call

      expect(result).to have_key('data')
      expect(result['data'].length).to eq(1)

      gateway_data = result['data'].first
      expect(gateway_data['name']).to eq('Paystack')
      expect(gateway_data['gateway_type']).to eq('paystack')
      expect(gateway_data['status']).to eq('active')
    end

    it 'includes gateway statistics' do
      result = described_class.call

      gateway_data = result['data'].first
      expect(gateway_data['payment_count']).to eq(3)
      expect(gateway_data['total_volume']).to eq(225.0) # 100 + 50 + 75
      expect(gateway_data['success_rate']).to eq(66.67) # 2 out of 3 completed
    end

    it 'includes fee information' do
      result = described_class.call

      gateway_data = result['data'].first
      expect(gateway_data['fee_breakdown']['base_fee']).to eq(10)
      expect(gateway_data['fee_breakdown']['percentage_fee']).to eq(1.5)
    end

    it 'includes supported currencies' do
      result = described_class.call

      gateway_data = result['data'].first
      expect(gateway_data['supported_currencies']).to eq([ 'USD', 'NGN', 'EUR' ])
      expect(gateway_data['supported_currencies_list']).to eq([ 'USD', 'NGN', 'EUR' ])
    end

    it 'includes last payment timestamp' do
      result = described_class.call

      gateway_data = result['data'].first
      expect(gateway_data['last_payment_at']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
    end

    context 'with no payments' do
      let!(:empty_gateway) {
        create(:payment_gateway,
               name: 'Empty Gateway',
               gateway_type: 'razorpay',
               status: 'active'
              )
      }

      it 'handles gateways with no payments' do
        result = described_class.call

        # Should include both gateways
        expect(result['data'].length).to eq(2)

        empty_gateway_data = result['data'].find { |g| g['name'] == 'Empty Gateway' }
        expect(empty_gateway_data['payment_count']).to eq(0)
        expect(empty_gateway_data['total_volume']).to eq(0)
        expect(empty_gateway_data['success_rate']).to eq(0)
        expect(empty_gateway_data['last_payment_at']).to be_nil
      end
    end

    context 'success rate calculation' do
      it 'calculates correct success rate' do
        # 2 completed out of 3 total = 66.67%
        result = described_class.call

        gateway_data = result['data'].find { |g| g['name'] == 'Paystack' }
        expect(gateway_data['success_rate']).to eq(66.67)
      end

      it 'returns 0 for gateways with no payments' do
        empty_gateway = create(:payment_gateway, gateway_type: 'razorpay', status: 'active')

        result = described_class.call

        empty_gateway_data = result['data'].find { |g| g['gateway_type'] == 'razorpay' }
        expect(empty_gateway_data['success_rate']).to eq(0)
      end
    end

    context 'Frappe API compatibility' do
      it 'returns exact field structure matching Frappe LMS' do
        result = described_class.call
        gateway_data = result['data'].first

        expected_fields = [
          'name', 'gateway_type', 'status', 'is_primary', 'supported_currencies',
          'fee_structure', 'creation', 'modified', 'payment_count', 'total_volume',
          'success_rate', 'supported_currencies_list', 'fee_breakdown', 'last_payment_at'
        ]

        expected_fields.each do |field|
          expect(gateway_data).to have_key(field), "Missing field: #{field}"
        end
      end

      it 'formats dates correctly' do
        result = described_class.call
        gateway_data = result['data'].first

        expect(gateway_data['creation']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(gateway_data['modified']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(gateway_data['last_payment_at']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end

      it 'includes proper gateway metadata' do
        result = described_class.call
        gateway_data = result['data'].first

        expect(gateway_data['name']).to eq(active_gateway.name)
        expect(gateway_data['gateway_type']).to eq(active_gateway.gateway_type)
        expect(gateway_data['status']).to eq(active_gateway.status)
        expect(gateway_data['is_primary']).to eq(active_gateway.is_primary)
      end
    end
  end
end
