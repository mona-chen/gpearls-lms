require 'rails_helper'
require './app/services/paystack_integration/paystack_service'

RSpec.describe PaystackIntegration::PaystackService, type: :service do
  let(:gateway) { create(:payment_gateway, gateway_type: 'paystack', status: 'active') }
  let(:user) { create(:user, phone: '+2348031234567') }
  let(:payment) { create(:payment, user: user, payment_method: 'paystack', amount: 5000, currency: 'NGN') }
  let(:service) { described_class.new(gateway) }

  describe '#initialize_transaction' do
    context 'with card payment' do
      it 'initializes a card payment transaction' do
        stub_paystack_request('/transaction/initialize', {
          status: true,
          data: {
            authorization_url: 'https://paystack.com/pay/test',
            access_code: 'test_code',
            reference: 'test_ref'
          }
        })

        result = service.initialize_transaction(payment)

        expect(result).to include(
          'authorization_url' => 'https://paystack.com/pay/test',
          'access_code' => 'test_code',
          'reference' => 'test_ref'
        )
        expect(payment.reload.transaction_id).to eq('test_ref')
      end
    end

    context 'with USSD payment' do
      let(:ussd_payment) { create(:payment, user: user, payment_method: 'paystack_ussd') }

      it 'initializes a USSD payment' do
        stub_paystack_request('/transaction/initialize', {
          status: true,
          data: {
            ussd_code: '*123*456#',
            reference: 'ussd_ref'
          }
        })

        result = service.initialize_transaction(ussd_payment, 'ussd')

        expect(result).to include(
          'ussd_code' => '*123*456#',
          'reference' => 'ussd_ref',
          'payment_method' => 'ussd'
        )
      end
    end

    context 'with bank transfer payment' do
      let(:bank_payment) { create(:payment, user: user, payment_method: 'paystack_bank_transfer') }

      it 'initializes a bank transfer payment' do
        stub_paystack_request('/transaction/initialize', {
          status: true,
          data: {
            account_number: '1234567890',
            account_name: 'Test Account',
            bank_name: 'Test Bank',
            bank_code: '001',
            reference: 'bank_ref'
          }
        })

        result = service.initialize_transaction(bank_payment, 'bank_transfer')

        expect(result).to include(
          'bank_details' => {
            'account_number' => '1234567890',
            'account_name' => 'Test Account',
            'bank_name' => 'Test Bank',
            'bank_code' => '001'
          },
          'reference' => 'bank_ref',
          'payment_method' => 'bank_transfer'
        )
      end
    end

    context 'with mobile money payment' do
      let(:mobile_payment) { create(:payment, user: user, payment_method: 'paystack_mobile_money') }

      it 'initializes a mobile money payment' do
        stub_paystack_request('/transaction/initialize', {
          status: true,
          data: {
            authorization_url: 'https://paystack.com/mobile/test',
            reference: 'mobile_ref'
          }
        })

        result = service.initialize_transaction(mobile_payment, 'mobile_money')

        expect(result).to include(
          'authorization_url' => 'https://paystack.com/mobile/test',
          'reference' => 'mobile_ref',
          'payment_method' => 'mobile_money'
        )
      end
    end
  end

  describe '#verify_transaction' do
    it 'verifies a successful transaction' do
      stub_paystack_request('/transaction/verify/test_ref', {
        status: true,
        data: {
          status: 'success',
          reference: 'test_ref',
          amount: 500000 # in kobo
        }
      })

      result = service.verify_transaction('test_ref')

      expect(result['status']).to eq('success')
      expect(payment.reload.payment_status).to eq('Completed')
    end

    it 'handles failed transaction' do
      stub_paystack_request('/transaction/verify/test_ref', {
        status: true,
        data: {
          status: 'failed',
          reference: 'test_ref'
        }
      })

      result = service.verify_transaction('test_ref')

      expect(result['status']).to eq('failed')
      expect(payment.reload.payment_status).to eq('Failed')
    end
  end

  describe '#initialize_ussd_payment' do
    it 'creates USSD payment' do
      stub_paystack_request('/transaction/initialize', {
        status: true,
        data: {
          ussd_code: '*123*789#',
          reference: 'ussd_test'
        }
      })

      result = service.initialize_ussd_payment(payment)

      expect(result['ussd_code']).to eq('*123*789#')
      expect(result['payment_method']).to eq('ussd')
    end
  end

  describe '#initialize_bank_transfer' do
    it 'creates bank transfer payment' do
      stub_paystack_request('/transaction/initialize', {
        status: true,
        data: {
          account_number: '0123456789',
          account_name: 'Payment Account',
          bank_name: 'Test Bank Nigeria',
          bank_code: '011',
          reference: 'bank_test'
        }
      })

      result = service.initialize_bank_transfer(payment)

      expect(result['bank_details']['account_number']).to eq('0123456789')
      expect(result['payment_method']).to eq('bank_transfer')
    end
  end

  describe '#initialize_mobile_money_payment' do
    it 'creates mobile money payment for MTN number' do
      stub_paystack_request('/transaction/initialize', {
        status: true,
        data: {
          authorization_url: 'https://paystack.com/mobile/mtn',
          reference: 'mobile_test'
        }
      })

      result = service.initialize_mobile_money_payment(payment)

      expect(result['authorization_url']).to eq('https://paystack.com/mobile/mtn')
      expect(result['payment_method']).to eq('mobile_money')
    end

    it 'returns error for missing phone number' do
      payment.user.update(phone_number: nil)

      result = service.initialize_mobile_money_payment(payment)

      expect(result['error']).to eq('Phone number required for mobile money')
    end
  end

  describe '#determine_mobile_provider' do
    test_cases = {
      '+2348031234567' => 'mtn',
      '+2348021234567' => 'airtel',
      '+2348051234567' => 'glo',
      '+2348091234567' => '9mobile',
      '+2347001234567' => 'unknown'
    }

    test_cases.each do |phone, expected_provider|
      it "detects #{expected_provider} for #{phone}" do
        expect(service.send(:determine_mobile_provider, phone)).to eq(expected_provider)
      end
    end
  end

  describe '#get_banks' do
    it 'retrieves list of supported banks' do
      stub_paystack_request('/bank', {
        status: true,
        data: [
          { name: 'Access Bank', code: '044' },
          { name: 'Zenith Bank', code: '057' }
        ]
      })

      result = service.get_banks

      expect(result).to be_an(Array)
      expect(result.first['name']).to eq('Access Bank')
    end
  end

  describe '#resolve_account_number' do
    it 'resolves account number details' do
      stub_paystack_request('/bank/resolve', {
        status: true,
        data: {
          account_number: '0123456789',
          account_name: 'John Doe',
          bank_id: 1
        }
      })

      result = service.resolve_account_number('0123456789', '044')

      expect(result['account_name']).to eq('John Doe')
      expect(result['account_number']).to eq('0123456789')
    end
  end

  describe '#validate_webhook_signature' do
    it 'validates correct webhook signature' do
      gateway.update_credentials(public_key: 'pk_test', secret_key: 'sk_test', webhook_secret: 'test_secret')
      payload = '{"event":"charge.success","data":{}}'
      signature = OpenSSL::HMAC.hexdigest('sha512', 'test_secret', payload)

      expect(service.validate_webhook_signature(payload, signature)).to be_truthy
    end

    it 'rejects invalid webhook signature' do
      gateway.update_credentials(public_key: 'pk_test', secret_key: 'sk_test', webhook_secret: 'test_secret')

      expect(service.validate_webhook_signature('{}', 'invalid')).to be_falsey
    end
  end

  describe '#process_webhook' do
    it 'processes successful charge webhook' do
      payment.update(transaction_id: 'webhook_ref')

      result = service.process_webhook({
        'event' => 'charge.success',
        'data' => { 'reference' => 'webhook_ref' }
      })

      expect(result['status']).to eq('processed')
      expect(payment.reload.payment_status).to eq('Completed')
    end

    it 'processes failed charge webhook' do
      payment.update(transaction_id: 'webhook_ref')

      result = service.process_webhook({
        'event' => 'charge.failed',
        'data' => { 'reference' => 'webhook_ref' }
      })

      expect(result['status']).to eq('processed')
      expect(payment.reload.payment_status).to eq('Failed')
    end
  end

  describe '#get_ussd_providers' do
    it 'retrieves USSD providers' do
      stub_paystack_request('/ussd/providers', {
        status: true,
        data: [
          { name: 'MTN', code: 'mtn' },
          { name: 'Airtel', code: 'airtel' }
        ]
      })

      result = service.get_ussd_providers

      expect(result).to be_an(Array)
      expect(result.first['name']).to eq('MTN')
    end
  end

  describe '#get_mobile_money_providers' do
    it 'returns list of supported mobile money providers' do
      result = service.get_mobile_money_providers

      expect(result).to be_an(Array)
      expect(result.first['code']).to eq('mtn')
      expect(result.first['countries']).to include('NG')
    end
  end

  def stub_paystack_request(endpoint, response_body)
    stub_request(:any, /api\.paystack\.co#{endpoint}/)
      .to_return(
        status: 200,
        body: response_body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
