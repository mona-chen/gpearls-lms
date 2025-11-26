class CreatePaymentGateways < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_gateways do |t|
      t.string :name, null: false
      t.string :gateway_type, null: false
      t.string :status, null: false, default: 'inactive'
      t.boolean :is_primary, default: false
      t.json :settings, null: false
      t.text :description
      t.text :webhook_url
      t.datetime :last_tested_at
      t.string :test_status
      t.text :test_response

      t.timestamps
    end

    add_index :payment_gateways, :name, unique: true
    add_index :payment_gateways, :gateway_type
    add_index :payment_gateways, :status
    add_index :payment_gateways, :is_primary
    add_index :payment_gateways, [ :gateway_type, :status ]

    # Insert default Paystack gateway configuration
    reversible do |dir|
      dir.up do
        PaymentGateway.create!(
          name: 'Paystack',
          gateway_type: 'paystack',
          status: 'sandbox',
          is_primary: true,
          settings: {
            'credentials' => {
              'public_key' => Rails.application.credentials.paystack&.dig(:sandbox, :public_key) || 'pk_test_000000000000000000000000000000',
              'secret_key' => Rails.application.credentials.paystack&.dig(:sandbox, :secret_key) || 'sk_test_000000000000000000000000000000',
              'webhook_secret' => Rails.application.credentials.paystack&.dig(:sandbox, :webhook_secret) || 'whsec_000000000000000000000000000000'
            },
            'supported_currencies' => %w[NGN USD GHS KES ZAR],
            'fees' => {
              'base' => 0.50,
              'percentage' => 1.5
            },
            'sandbox_mode' => true,
            'auto_refund' => false,
            'max_refund_days' => 30
          },
          description: 'Paystack - Leading African payment gateway',
          webhook_url: "#{Rails.application.routes.default_url_options[:host]}/api/payments/callback/paystack"
        )

        PaymentGateway.create!(
          name: 'Stripe',
          gateway_type: 'stripe',
          status: 'inactive',
          is_primary: false,
          settings: {
            'credentials' => {
              'publishable_key' => Rails.application.credentials.stripe&.dig(:test, :publishable_key) || 'pk_test_000000000000000000000000000000',
              'secret_key' => Rails.application.credentials.stripe&.dig(:test, :secret_key) || 'sk_test_000000000000000000000000000000',
              'webhook_secret' => Rails.application.credentials.stripe&.dig(:test, :webhook_secret) || 'whsec_000000000000000000000000000000'
            },
            'supported_currencies' => %w[USD EUR GBP],
            'fees' => {
              'base' => 0.30,
              'percentage' => 2.9
            },
            'sandbox_mode' => true,
            'auto_refund' => false,
            'max_refund_days' => 30
          },
          description: 'Stripe - Global payment processing'
        )

        PaymentGateway.create!(
          name: 'Razorpay',
          gateway_type: 'razorpay',
          status: 'inactive',
          is_primary: false,
          settings: {
            'credentials' => {
              'key_id' => Rails.application.credentials.razorpay&.dig(:test, :key_id) || 'rzp_test_000000000000000000000000000000',
              'key_secret' => Rails.application.credentials.razorpay&.dig(:test, :key_secret) || 'rzp_test_000000000000000000000000000000',
              'webhook_secret' => Rails.application.credentials.razorpay&.dig(:test, :webhook_secret) || 'whsec_000000000000000000000000000000'
            },
            'supported_currencies' => %w[INR USD],
            'fees' => {
              'base' => 0.00,
              'percentage' => 2.0
            },
            'sandbox_mode' => true,
            'auto_refund' => false,
            'max_refund_days' => 30
          },
          description: 'Razorpay - Indian payment gateway'
        )
      end

      dir.down do
        PaymentGateway.where(gateway_type: %w[paystack stripe razorpay]).delete_all
      end
    end
  end
end
