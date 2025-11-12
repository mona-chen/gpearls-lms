class AdminMailer < ApplicationMailer
  default from: 'admin@lms.test'

  def payment_dispute_notification(payment, dispute_data)
    @payment = payment
    @dispute_data = dispute_data
    @user = payment.user
    @item = payment.course || payment.batch || payment.program

    mail(
      to: Rails.application.config.admin_email || 'admin@lms.test',
      subject: "🚨 Payment Dispute - #{@item&.title || 'Payment'} ##{payment.name}"
    )
  end

  def payment_failure_notification(payment, error_details = nil)
    @payment = payment
    @user = payment.user
    @item = payment.course || payment.batch || payment.program
    @error_details = error_details

    mail(
      to: Rails.application.config.admin_email || 'admin@lms.test',
      subject: "⚠️ Payment Failed - #{@item&.title || 'Payment'} ##{payment.name}"
    )
  end

  def high_value_payment_notification(payment)
    @payment = payment
    @user = payment.user
    @item = payment.course || payment.batch || payment.program

    mail(
      to: Rails.application.config.admin_email || 'admin@lms.test',
      subject: "💰 High Value Payment - #{@item&.title} - #{payment.amount} #{payment.currency}"
    )
  end

  def gateway_connection_failed(gateway_name, error_details)
    @gateway_name = gateway_name
    @error_details = error_details
    @timestamp = Time.current

    mail(
      to: Rails.application.config.admin_email || 'admin@lms.test',
      subject: "🔌 Gateway Connection Failed - #{@gateway_name}"
    )
  end

  def fraud_detection_alert(payment, risk_score, suspicious_activities)
    @payment = payment
    @user = payment.user
    @risk_score = risk_score
    @suspicious_activities = suspicious_activities
    @item = payment.course || payment.batch || payment.program

    mail(
      to: Rails.application.config.admin_email || 'admin@lms.test',
      subject: "🚨 Fraud Alert - High Risk Payment Detected"
    )
  end

  def refund_request_notification(payment, refund_amount, reason)
    @payment = payment
    @user = payment.user
    @refund_amount = refund_amount
    @reason = reason
    @item = payment.course || payment.batch || payment.program

    mail(
      to: Rails.application.config.admin_email || 'admin@lms.test',
      subject: "📋 Refund Request - #{@item&.title} - #{@refund_amount} #{@payment.currency}"
    )
  end

  def daily_payment_summary(date = Date.yesterday, stats = {})
    @date = date
    @stats = stats
    @total_payments = stats[:total_payments] || 0
    @total_amount = stats[:total_amount] || 0
    @successful_payments = stats[:successful_payments] || 0
    @failed_payments = stats[:failed_payments] || 0
    @refunds = stats[:refunds] || 0

    mail(
      to: Rails.application.config.admin_email || 'admin@lms.test',
      subject: "📊 Daily Payment Summary - #{@date.strftime('%B %d, %Y')}"
    )
  end

  def new_gateway_setup(gateway_name, setup_details)
    @gateway_name = gateway_name
    @setup_details = setup_details
    @admin_email = setup_details[:admin_email]

    mail(
      to: @admin_email,
      subject: "✅ New Payment Gateway Setup - #{@gateway_name}"
    )
  end

  def payment_method_added(user, payment_method)
    @user = user
    @payment_method = payment_method

    mail(
      to: Rails.application.config.admin_email || 'admin@lms.test',
      subject: "💳 New Payment Method Added - #{@user.email}"
    )
  end

  def subscription_cancellation_warning(subscription, warning_days = 7)
    @subscription = subscription
    @user = subscription.user
    @warning_days = warning_days
    @item = subscription.course || subscription.batch || subscription.program

    mail(
      to: Rails.application.config.admin_email || 'admin@lms.test',
      subject: "⏰ Subscription Cancellation Warning - #{@item&.title}"
    )
  end

  def revenue_milestone_alert(milestone_amount, current_revenue, period)
    @milestone_amount = milestone_amount
    @current_revenue = current_revenue
    @period = period
    @growth_percentage = calculate_growth_percentage(current_revenue, milestone_amount)

    mail(
      to: Rails.application.config.admin_email || 'admin@lms.test',
      subject: "🎯 Revenue Milestone Reached - #{current_revenue} USD"
    )
  end

  private

  def calculate_growth_percentage(current, milestone)
    return 0 if milestone <= 0
    ((current - milestone) / milestone.to_f * 100).round(2)
  end
end
