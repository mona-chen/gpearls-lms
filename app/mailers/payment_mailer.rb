class PaymentMailer < ApplicationMailer
  default from: "payments@lms.test"

  def payment_confirmation(payment)
    @payment = payment
    @user = payment.user
    @item = payment.course || payment.batch || payment.program

    mail(
      to: @user.email,
      subject: "Payment Confirmation - #{@item&.title || 'Your Purchase'}"
    )
  end

  def payment_failure(payment)
    @payment = payment
    @user = payment.user
    @item = payment.course || payment.batch || payment.program

    mail(
      to: @user.email,
      subject: "Payment Failed - #{@item&.title || 'Your Purchase'}"
    )
  end

  def refund_confirmation(payment)
    @payment = payment
    @user = payment.user
    @item = payment.course || payment.batch || payment.program

    mail(
      to: @user.email,
      subject: "Refund Processed - #{@item&.title || 'Your Purchase'}"
    )
  end

  def payment_reminder(payment)
    @payment = payment
    @user = payment.user
    @item = payment.course || payment.batch || payment.program

    mail(
      to: @user.email,
      subject: "Payment Reminder - #{@item&.title || 'Your Purchase'}"
    )
  end

  def payment_dispute_notification(payment, dispute_data)
    @payment = payment
    @user = payment.user
    @dispute_data = dispute_data
    @item = payment.course || payment.batch || payment.program

    mail(
      to: Rails.application.config.admin_email,
      subject: "Payment Dispute - #{@item&.title || 'Payment'} ##{payment.name}"
    )
  end

  def payment_method_added(user, payment_method)
    @user = user
    @payment_method = payment_method

    mail(
      to: @user.email,
      subject: "Payment Method Added Successfully"
    )
  end

  def subscription_renewal_failed(subscription)
    @subscription = subscription
    @user = subscription.user

    mail(
      to: @user.email,
      subject: "Subscription Renewal Failed"
    )
  end

  def subscription_renewed(subscription)
    @subscription = subscription
    @user = subscription.user

    mail(
      to: @user.email,
      subject: "Subscription Renewed Successfully"
    )
  end
end
