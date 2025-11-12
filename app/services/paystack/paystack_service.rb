module Paystack
  class PaystackService
    include HTTParty

    base_uri "https://api.paystack.co"

    def initialize(gateway = nil)
      @gateway = gateway || PaymentGateway.active_for_type("paystack")
      raise Error::GatewayNotConfiguredError, "Paystack gateway not configured" unless @gateway&.active?

      @secret_key = @gateway.credentials[:secret_key]
      @public_key = @gateway.credentials[:public_key]
    end

    # Initialize a payment transaction
    def initialize_transaction(payment, payment_method = nil)
      payload = {
        email: payment.user.email,
        amount: (payment.amount * 100).to_i, # Convert to kobo/cents
        currency: payment.currency,
        reference: payment.name,
        callback_url: payment_callback_url(payment),
        metadata: {
          payment_id: payment.id,
          custom_fields: [
            {
              display_name: "Payment Description",
              variable_name: "payment_description",
              value: payment.payment_description
            }
          ]
        }
      }

      # Add optional fields
      payload[:plan] = payment.plan_id if payment.respond_to?(:plan_id) && payment.plan_id.present?
      payload[:subaccount] = payment.subaccount_code if payment.respond_to?(:subaccount_code) && payment.subaccount_code.present?
      payload[:transaction_charge] = payment.transaction_charge if payment.respond_to?(:transaction_charge) && payment.transaction_charge.present?
      payload[:bearer] = payment.bearer || "account"

      # Add Nigerian payment method specific fields
      case payment_method
      when "ussd"
        payload[:payment_method] = "ussd"
        payload[:ussd] = { type: "paycode" } # Paystack generates USSD code
      when "bank_transfer"
        payload[:payment_method] = "bank_transfer"
      when "mobile_money"
        payload[:payment_method] = "mobile_money"
        # Mobile money requires additional parameters like phone number
        payload[:mobile_money] = {
          phone: payment.user.phone_number,
          provider: determine_mobile_provider(payment.user.phone_number)
        }
      end

      response = self.class.post("/transaction/initialize", {
        body: payload.to_json,
        headers: auth_headers
      })

      handle_response(response) do |data|
        payment.update!(transaction_id: data["reference"])

        # Start automatic polling for this transaction
        payment.start_polling!

        # Return appropriate response based on payment method
        case payment_method
        when "ussd"
          {
            ussd_code: data["ussd_code"],
            reference: data["reference"],
            payment_method: "ussd"
          }
        when "bank_transfer"
          {
            bank_details: data["bank_details"],
            reference: data["reference"],
            payment_method: "bank_transfer"
          }
        when "mobile_money"
          {
            payment_url: data["authorization_url"],
            reference: data["reference"],
            payment_method: "mobile_money"
          }
        else
          {
            authorization_url: data["authorization_url"],
            access_code: data["access_code"],
            reference: data["reference"]
          }
        end
      end
    end

    # Verify a payment transaction
    def verify_transaction(reference)
      response = self.class.get("/transaction/verify/#{reference}", {
        headers: auth_headers
      })

      handle_response(response) do |data|
        payment = Payment.find_by(transaction_id: reference)
        return { error: "Payment not found" } unless payment

        if data["status"] == "success"
          payment.mark_completed!(data)
          payment.stop_polling! # Stop polling when payment is completed

          # Process payment based on type
          process_payment_completion(payment, data)

          {
            status: "success",
            payment: payment,
            gateway_response: data
          }
        else
          payment.mark_failed!(data)
          payment.stop_polling! # Stop polling when payment fails

          {
            status: "failed",
            payment: payment,
            gateway_response: data
          }
        end
      end
    end

    # Charge an existing customer
    def charge_authorization(payment, authorization_code)
      payload = {
        email: payment.user.email,
        amount: (payment.amount * 100).to_i,
        currency: payment.currency,
        reference: payment.name,
        authorization_code: authorization_code,
        metadata: {
          payment_id: payment.id
        }
      }

      response = self.class.post("/transaction/charge_authorization", {
        body: payload.to_json,
        headers: auth_headers
      })

      handle_response(response) do |data|
        if data["status"] == "success"
          payment.mark_completed!(data)
          process_payment_completion(payment, data)
        else
          payment.mark_failed!(data)
        end

        {
          payment: payment,
          gateway_response: data
        }
      end
    end

    # Create a customer
    def create_customer(user)
      payload = {
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone_number,
        metadata: {
          user_id: user.id
        }
      }

      response = self.class.post("/customer", {
        body: payload.to_json,
        headers: auth_headers
      })

      handle_response(response) do |data|
        {
          customer_code: data["customer_code"],
          customer_id: data["id"],
          email: data["email"]
        }
      end
    end

    # Get transaction history
    def get_transactions(options = {})
      params = {
        perPage: options[:per_page] || 50,
        page: options[:page] || 1
      }

      params[:from] = options[:from].to_i if options[:from]
      params[:to] = options[:to].to_i if options[:to]
      params[:status] = options[:status] if options[:status]

      response = self.class.get("/transaction", {
        query: params,
        headers: auth_headers
      })

      handle_response(response) do |data|
        {
          transactions: data["data"] || [],
          meta: data["meta"] || {}
        }
      end
    end

    # Process refund
    def process_refund(payment, amount = nil)
      refund_amount = amount || payment.amount

      payload = {
        transaction: payment.transaction_id,
        amount: (refund_amount * 100).to_i,
        currency: payment.currency
      }

      response = self.class.post("/refund", {
        body: payload.to_json,
        headers: auth_headers
      })

      handle_response(response) do |data|
        payment.mark_refunded!(data)

        {
          refund_id: data["id"],
          status: data["status"],
          amount: data["amount"],
          gateway_response: data
        }
      end
    end

    # Validate webhook signature
    def validate_webhook_signature(payload, signature)
      return false unless @gateway&.credentials[:webhook_secret]

      computed_signature = OpenSSL::HMAC.hexdigest(
        "sha512",
        @gateway.credentials[:webhook_secret],
        payload
      )

      ActiveSupport::SecurityUtils.secure_compare(computed_signature, signature)
    end

    # Process webhook events
    def process_webhook(payload)
      event = payload["event"]
      data = payload["data"]

      case event
      when "charge.success"
        handle_successful_charge(data)
      when "charge.failed"
        handle_failed_charge(data)
      when "charge.dispute.create"
        handle_dispute_creation(data)
      when "refund.processed"
        handle_refund_processed(data)
      when "subscription.create"
        handle_subscription_creation(data)
      when "invoice.create"
        handle_invoice_creation(data)
      else
        Rails.logger.info "Unhandled Paystack webhook event: #{event}"
      end

      { status: "processed", event: event }
    end

    # Get banks for transfer
    def get_banks
      response = self.class.get("/bank", {
        headers: auth_headers
      })

      handle_response(response) do |data|
        data["data"] || []
      end
    end

    # Resolve account number
    def resolve_account_number(account_number, bank_code)
      payload = {
        account_number: account_number,
        bank_code: bank_code
      }

      response = self.class.post("/bank/resolve", {
        body: payload.to_json,
        headers: auth_headers
      })

      handle_response(response) do |data|
        {
          account_number: data["data"]["account_number"],
          account_name: data["data"]["account_name"],
          bank_id: data["data"]["bank_id"]
        }
      end
    end

    # Create transfer recipient
    def create_transfer_recipient(details)
      payload = {
        type: details[:type] || "nuban",
        name: details[:name],
        account_number: details[:account_number],
        bank_code: details[:bank_code],
        currency: details[:currency] || "NGN"
      }

      response = self.class.post("/transferrecipient", {
        body: payload.to_json,
        headers: auth_headers
      })

      handle_response(response) do |data|
        {
          recipient_code: data["data"]["recipient_code"],
          type: data["data"]["type"],
          name: data["data"]["name"]
        }
      end
    end

    # Initialize transfer
    def initialize_transfer(details)
      payload = {
        source: details[:source] || "balance",
        amount: (details[:amount] * 100).to_i,
        recipient: details[:recipient_code],
        reason: details[:reason],
        currency: details[:currency] || "NGN",
        reference: details[:reference]
      }

      response = self.class.post("/transfer", {
        body: payload.to_json,
        headers: auth_headers
      })

      handle_response(response) do |data|
        {
          transfer_code: data["data"]["transfer_code"],
          reference: data["data"]["reference"],
          amount: data["data"]["amount"],
          status: data["data"]["status"]
        }
      end
    end

    # Initialize USSD payment
    def initialize_ussd_payment(payment)
      initialize_transaction(payment, "ussd")
    end

    # Initialize bank transfer payment
    def initialize_bank_transfer(payment)
      payload = {
        email: payment.user.email,
        amount: (payment.amount * 100).to_i,
        currency: payment.currency,
        reference: payment.name,
        payment_method: "bank_transfer",
        callback_url: payment_callback_url(payment),
        metadata: {
          payment_id: payment.id,
          payment_method: "bank_transfer"
        }
      }

      response = self.class.post("/transaction/initialize", {
        body: payload.to_json,
        headers: auth_headers
      })

      handle_response(response) do |data|
        payment.update!(transaction_id: data["reference"])
        payment.start_polling!

        {
          bank_details: {
            account_number: data["account_number"],
            account_name: data["account_name"],
            bank_name: data["bank_name"],
            bank_code: data["bank_code"]
          },
          reference: data["reference"],
          payment_method: "bank_transfer"
        }
      end
    end

    # Initialize mobile money payment
    def initialize_mobile_money_payment(payment)
      return { error: "Phone number required for mobile money" } unless payment.user.phone_number.present?

      payload = {
        email: payment.user.email,
        amount: (payment.amount * 100).to_i,
        currency: payment.currency,
        reference: payment.name,
        payment_method: "mobile_money",
        mobile_money: {
          phone: payment.user.phone_number,
          provider: determine_mobile_provider(payment.user.phone_number)
        },
        callback_url: payment_callback_url(payment),
        metadata: {
          payment_id: payment.id,
          payment_method: "mobile_money"
        }
      }

      response = self.class.post("/transaction/initialize", {
        body: payload.to_json,
        headers: auth_headers
      })

      handle_response(response) do |data|
        payment.update!(transaction_id: data["reference"])
        payment.start_polling!

        {
          authorization_url: data["authorization_url"],
          reference: data["reference"],
          payment_method: "mobile_money",
          provider: determine_mobile_provider(payment.user.phone_number)
        }
      end
    end

    # Get USSD providers
    def get_ussd_providers
      response = self.class.get("/ussd/providers", {
        headers: auth_headers
      })

      handle_response(response) do |data|
        data["data"] || []
      end
    end

    # Get supported mobile money providers
    def get_mobile_money_providers
      # Paystack supports mobile money in various African countries
      # For Nigeria, this would include providers like MTN, Airtel, etc.
      [
        { code: "mtn", name: "MTN Mobile Money", countries: [ "NG", "GH", "CI" ] },
        { code: "airtel", name: "Airtel Money", countries: [ "NG", "TZ", "KE", "UG" ] },
        { code: "vodafone", name: "Vodafone Cash", countries: [ "GH", "CI" ] },
        { code: "tigo", name: "Tigo Cash", countries: [ "GH" ] }
      ]
    end
  end

    private

    def auth_headers
      {
        "Authorization" => "Bearer #{@secret_key}",
        "Content-Type" => "application/json"
      }
    end

    def handle_response(response)
      parsed_response = JSON.parse(response.body)

      if response.success? && parsed_response["status"]
        yield(parsed_response["data"]) if block_given?
        parsed_response
      else
        error_message = parsed_response["message"] || "Paystack API error"
        raise Error::PaystackError, error_message
      end

    rescue JSON::ParserError => e
      raise Error::PaystackError, "Invalid response from Paystack: #{e.message}"
    end

    def payment_callback_url(payment)
      "#{Rails.application.routes.default_url_options[:host]}/api/payments/callback/paystack"
    end

    def process_payment_completion(payment, gateway_data)
      # Handle different payment types
      if payment.course.present?
        enroll_user_in_course(payment.user, payment.course)
      elsif payment.batch.present?
        enroll_user_in_batch(payment.user, payment.batch)
      elsif payment.program.present?
        enroll_user_in_program(payment.user, payment.program)
      end

      # Send notifications
      PaymentMailer.payment_confirmation(payment).deliver_later

      # Create payment log
      PaymentLog.create!(
        payment: payment,
        event_type: "payment_completed",
        gateway_response: gateway_data,
        status: "success"
      )
    end

    def handle_successful_charge(data)
      payment = Payment.find_by(transaction_id: data["reference"])
      return unless payment

      payment.mark_completed!(data)
      payment.stop_polling! # Stop polling when payment is completed via webhook
      process_payment_completion(payment, data)
    end

    def handle_failed_charge(data)
      payment = Payment.find_by(transaction_id: data["reference"])
      return unless payment

      payment.mark_failed!(data)
      payment.stop_polling! # Stop polling when payment fails via webhook

      PaymentMailer.payment_failure(payment).deliver_later
    end

    def handle_dispute_creation(data)
      payment = Payment.find_by(transaction_id: data["reference"])
      return unless payment

      # Log dispute and notify admin
      PaymentLog.create!(
        payment: payment,
        event_type: "dispute_created",
        gateway_response: data,
        status: "warning"
      )

      AdminMailer.payment_dispute_notification(payment, data).deliver_later
    end

    def handle_refund_processed(data)
      payment = Payment.find_by(transaction_id: data["reference"])
      return unless payment

      payment.mark_refunded!(data)

      PaymentMailer.refund_confirmation(payment).deliver_later
    end

    def handle_subscription_creation(data)
      # Handle subscription creation if applicable
      Rails.logger.info "Subscription created: #{data}"
    end

    def handle_invoice_creation(data)
      # Handle invoice creation if applicable
      Rails.logger.info "Invoice created: #{data}"
    end

    def enroll_user_in_course(user, course)
      enrollment = Enrollment.find_or_create_by!(user: user, course: course)
      enrollment.update!(status: "Active", enrollment_date: Time.current)
    end

    def enroll_user_in_batch(user, batch)
      batch_enrollment = BatchEnrollment.find_or_create_by!(user: user, batch: batch)
      batch_enrollment.update!(status: "Active", enrollment_date: Time.current)
    end

    def enroll_user_in_program(user, program)
      program_enrollment = LmsProgramEnrollment.find_or_create_by!(user: user, program: program)
      program_enrollment.update!(status: "Active", enrollment_date: Time.current)
    end

    def determine_mobile_provider(phone_number)
      return nil unless phone_number.present?

      # Remove country code and formatting
      clean_number = phone_number.gsub(/[^\d]/, "").gsub(/^234/, "")

      # Nigerian mobile number prefixes
      case clean_number[0..2]
      when "703", "706", "803", "806", "810", "813", "814", "816", "903", "906"
        "mtn"
      when "701", "708", "802", "808", "812", "901", "902", "904", "907", "912"
        "airtel"
      when "705", "805", "807", "811", "815", "905", "915"
        "glo"
      when "809", "817", "818", "909", "908"
        "9mobile"
      else
        "unknown"
      end
  end
end
