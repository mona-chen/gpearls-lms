require 'rails_helper'

RSpec.describe 'Paystack Integration', type: :service do
  describe 'Nigerian Payment Methods' do
    let(:gateway) { double('PaymentGateway', active?: true, credentials: { secret_key: 'sk_test_123', public_key: 'pk_test_123', webhook_secret: 'wh_test_123' }) }
    let(:user) { double('User', email: 'test@example.com', phone_number: '+2348031234567', full_name: 'Test User') }
    let(:payment) { double('Payment', id: 1, name: 'PAY001', amount: 5000, currency: 'NGN', user: user, transaction_id: nil, payment_method: 'paystack') }

    before do
      allow(payment).to receive(:update!)
      allow(payment).to receive(:start_polling!)
      allow(PaymentGateway).to receive(:active_for_type).and_return(gateway)
    end

    describe 'USSD Payment' do
      it 'initializes USSD payment correctly' do
        service = PaystackModule::PaystackService.new(gateway)

        stub_request(:post, 'https://api.paystack.co/transaction/initialize')
          .to_return(
            status: 200,
            body: {
              status: true,
              data: {
                ussd_code: '*123*456#',
                reference: 'ussd_ref_123'
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = service.initialize_ussd_payment(payment)

        expect(result['ussd_code']).to eq('*123*456#')
        expect(result['reference']).to eq('ussd_ref_123')
        expect(result['payment_method']).to eq('ussd')
      end
    end

    describe 'Bank Transfer Payment' do
      it 'initializes bank transfer payment correctly' do
        service = PaystackModule::PaystackService.new(gateway)

        stub_request(:post, 'https://api.paystack.co/transaction/initialize')
          .to_return(
            status: 200,
            body: {
              status: true,
              data: {
                account_number: '1234567890',
                account_name: 'Test Account',
                bank_name: 'Test Bank Nigeria',
                bank_code: '011',
                reference: 'bank_ref_123'
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = service.initialize_bank_transfer(payment)

        expect(result['bank_details']['account_number']).to eq('1234567890')
        expect(result['bank_details']['account_name']).to eq('Test Account')
        expect(result['bank_details']['bank_name']).to eq('Test Bank Nigeria')
        expect(result['payment_method']).to eq('bank_transfer')
      end
    end

    describe 'Mobile Money Payment' do
      it 'initializes mobile money payment for MTN' do
        service = PaystackModule::PaystackService.new(gateway)

        stub_request(:post, 'https://api.paystack.co/transaction/initialize')
          .to_return(
            status: 200,
            body: {
              status: true,
              data: {
                authorization_url: 'https://paystack.com/mobile/mtn',
                reference: 'mobile_ref_123'
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = service.initialize_mobile_money_payment(payment)

        expect(result['authorization_url']).to eq('https://paystack.com/mobile/mtn')
        expect(result['reference']).to eq('mobile_ref_123')
        expect(result['payment_method']).to eq('mobile_money')
      end

      it 'returns error for missing phone number' do
        user_without_phone = double('User', email: 'test@example.com', phone_number: nil, full_name: 'Test User')
        payment_without_phone = double('Payment', id: 1, name: 'PAY001', amount: 5000, currency: 'NGN', user: user_without_phone, transaction_id: nil, payment_method: 'paystack_mobile_money')

        service = PaystackModule::PaystackService.new(gateway)

        result = service.initialize_mobile_money_payment(payment_without_phone)

        expect(result['error']).to eq('Phone number required for mobile money')
      end
    end

    describe 'Mobile Provider Detection' do
      it 'correctly identifies Nigerian mobile providers' do
        service = PaystackModule::PaystackService.new(gateway)

        test_cases = {
          '+2348031234567' => 'mtn',
          '+2348021234567' => 'airtel',
          '+2348051234567' => 'glo',
          '+2348091234567' => '9mobile',
          '+2347001234567' => 'unknown'
        }

        test_cases.each do |phone, expected_provider|
          expect(service.send(:determine_mobile_provider, phone)).to eq(expected_provider)
        end
      end
    end

    describe 'Bank Operations' do
      it 'retrieves list of supported banks' do
        service = PaystackModule::PaystackService.new(gateway)

        stub_request(:get, 'https://api.paystack.co/bank')
          .to_return(
            status: 200,
            body: {
              status: true,
              data: [
                { name: 'Access Bank', code: '044' },
                { name: 'Zenith Bank', code: '057' }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = service.get_banks

        expect(result).to be_an(Array)
        expect(result.first['name']).to eq('Access Bank')
        expect(result.first['code']).to eq('044')
      end

      it 'resolves account number details' do
        service = PaystackModule::PaystackService.new(gateway)

        stub_request(:post, 'https://api.paystack.co/bank/resolve')
          .to_return(
            status: 200,
            body: {
              status: true,
              data: {
                account_number: '0123456789',
                account_name: 'John Doe',
                bank_id: 1
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = service.resolve_account_number('0123456789', '044')

        expect(result['account_name']).to eq('John Doe')
        expect(result['account_number']).to eq('0123456789')
      end
    end

    describe 'Webhook Security' do
      it 'validates correct webhook signature' do
        service = PaystackModule::PaystackService.new(gateway)
        payload = '{"event":"charge.success","data":{}}'
        signature = OpenSSL::HMAC.hexdigest('sha512', 'wh_test_123', payload)

        expect(service.validate_webhook_signature(payload, signature)).to be_truthy
      end

      it 'rejects invalid webhook signature' do
        service = PaystackModule::PaystackService.new(gateway)

        expect(service.validate_webhook_signature('{}', 'invalid')).to be_falsey
      end
    end

    describe 'Supported Mobile Money Providers' do
      it 'returns comprehensive list of mobile money providers' do
        service = PaystackModule::PaystackService.new(gateway)

        providers = service.get_mobile_money_providers

        expect(providers).to be_an(Array)
        expect(providers.first['code']).to eq('mtn')
        expect(providers.first['countries']).to include('NG')
      end
    end
  end
end
