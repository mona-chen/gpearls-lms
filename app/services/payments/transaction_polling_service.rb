module Payments
  class TransactionPollingService
    include Sidekiq::Worker

    sidekiq_options retry: 3, queue: "payments"
    sidekiq_retry_in { 5.minutes }

    # Polling settings
    POLLING_INTERVAL = 30.seconds # Check every 30 seconds
    MAX_POLLING_TIME = 30.minutes # Stop polling after 30 minutes
    MAX_POLLS_PER_PAYMENT = 60 # Maximum polls per payment

    def perform(payment_id)
      @payment = Payment.find(payment_id)

      return unless @payment&.pending?
      return if polling_expired?
      return if max_polls_reached?

      Rails.logger.info "Polling payment #{@payment.id} (attempt #{@payment.poll_count + 1})"

      begin
        poll_transaction_status
        @payment.update!(last_polled_at: Time.current, poll_count: @payment.poll_count + 1)

        # Schedule next poll if still pending
        if @payment.pending? && !polling_expired?
          schedule_next_poll
        end
      rescue => e
        Rails.logger.error "Error polling transaction #{@payment.id}: #{e.message}"
        handle_polling_error(e)
      end
    end

    def self.start_polling(payment_id)
      payment = Payment.find(payment_id)
      return unless payment&.pending?

      payment.update!(
        last_polled_at: Time.current,
        polling_expires_at: MAX_POLLING_TIME.from_now,
        auto_verification_enabled: true
      )

      # Enqueue the polling job
      perform_async(payment_id)
    end

    def self.poll_all_pending_transactions
      Rails.logger.info "Starting batch polling of pending transactions"

      Payment.pending
             .where(auto_verification_enabled: true)
             .where("created_at > ?", 1.hour.ago)
             .where("polling_expires_at > ? OR polling_expires_at IS NULL", Time.current)
             .where("last_polled_at < ? OR last_polled_at IS NULL", 30.seconds.ago)
             .find_each do |payment|
        # Check if already being processed
        next if Sidekiq::Status::Worker.status(payment.id.to_s, self.class)&.dig("status") == "running"

        # Enqueue the polling job if not already running
        unless self.class.perform_in_async(30.seconds, payment.id)
          Rails.logger.warn "Failed to schedule polling for payment #{payment.id} - possibly already in queue"
        end
      end
    end

    def self.cleanup_expired_polls
      expired_count = Payment.pending
                           .where("polling_expires_at < ?", Time.current)
                           .update_all(
                             payment_status: "Failed",
                             notes: "Marked as failed due to polling timeout",
                             auto_verification_enabled: false
                           )

      Rails.logger.info "Cleaned up #{expired_count} expired payment polls" if expired_count > 0
    end

    private

    def poll_transaction_status
      case @payment.payment_method
      when "paystack"
        poll_paystack_transaction
      when "stripe"
        poll_stripe_transaction
      when "razorpay"
        poll_razorpay_transaction
      else
        Rails.logger.warn "Unsupported payment method for polling: #{@payment.payment_method}"
      end
    end

    def poll_paystack_transaction
      service = PaystackIntegration::PaystackService.new
      result = service.verify_transaction(@payment.transaction_id)

      if result[:status] == "success"
        Rails.logger.info "Payment #{@payment.id} completed via polling"
        @payment.stop_polling!
      else
        # Payment is still pending, will be polled again on next run
        Rails.logger.debug "Payment #{@payment.id} still pending, will poll again"
      end
    end

    def poll_stripe_transaction
      service = Stripe::StripeService.new
      intent = service.get_payment_intent(@payment.transaction_id)

      if intent.status == "succeeded"
        service.confirm_payment(@payment.transaction_id)
        @payment.stop_polling!
      elsif intent.status.in?([ "canceled", "failed" ])
        @payment.mark_failed!(gateway_response: intent.to_json)
        @payment.stop_polling!
      else
        Rails.logger.debug "Stripe payment #{@payment.id} still in status: #{intent.status}"
      end
    end

    def poll_razorpay_transaction
      service = Razorpay::RazorpayService.new
      order = service.get_order(@payment.transaction_id)

      if order.status == "paid"
        @payment.mark_completed!(gateway_response: order.to_json)
        @payment.stop_polling!
      elsif order.status.in?([ "expired", "failed" ])
        @payment.mark_failed!(gateway_response: order.to_json)
        @payment.stop_polling!
      else
        Rails.logger.debug "Razorpay payment #{@payment.id} still in status: #{order.status}"
      end
    end

    def polling_expired?
      @payment.polling_expires_at.present? && @payment.polling_expires_at < Time.current
    end

    def max_polls_reached?
      @payment.poll_count >= MAX_POLLS_PER_PAYMENT
    end

    def handle_polling_error(error)
      PaymentLog.create!(
        payment: @payment,
        event_type: "polling_error",
        status: "error",
        error_message: error.message,
        gateway_type: @payment.payment_method
      )

      # Mark as failed if too many errors or polls
      if max_polls_reached? || @payment.poll_count > 10
        @payment.mark_failed!(error: "Max polling attempts reached: #{error.message}")
        @payment.stop_polling!
      end
    end

    def schedule_next_poll
      return if max_polls_reached?

      delay = calculate_polling_delay
      self.class.perform_in(delay, @payment.id)
    end

    def calculate_polling_delay
      base_delay = 5.seconds
      poll_number = (@payment.poll_count || 0) + 1

      # Exponential backoff with jitter
      delay = base_delay * (2 ** [ poll_number - 1, 8 ].min)
      jitter = rand(0.1..0.3) * delay

      delay + jitter
    end

    def self.log_polling_statistics
      stats = get_polling_statistics
      Rails.logger.info "Polling Statistics: #{stats}"

      # Send admin notification if too many failed polls
      if stats[:failed_polls] > 10
        AdminMailer.payment_failure_notification(
          nil,
          { error: "High number of failed payment polls: #{stats[:failed_polls]}" }
        ).deliver_later
      end
    end

    def self.get_polling_statistics
      {
        total_pending: Payment.pending.count,
        pending_last_hour: Payment.pending.where("created_at > ?", 1.hour.ago).count,
        polling_active: Payment.pending.where(auto_verification_enabled: true).count,
        expired_polls: Payment.pending.where("polling_expires_at < ?", Time.current).count,
        high_poll_count: Payment.pending.where("poll_count > ?", 30).count,
        sidekiq_queue_size: Sidekiq::Queue.new("payments").size,
        active_workers: Sidekiq::Workers.new.size
      }
    end
  end
end
