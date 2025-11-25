class SetupWizardController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :check_setup_completion

  def index
    @step = params[:step].presence || 'welcome'
    @setup_data = session[:setup_data] || {}

    case @step
    when 'welcome'
      render :welcome
    when 'site_settings'
      render :site_settings
    when 'admin_user'
      render :admin_user
    when 'payment_settings'
      render :payment_settings
    when 'email_settings'
      render :email_settings
    when 'complete'
      render :complete
    else
      redirect_to setup_wizard_path(step: 'welcome')
    end
  end

  def update
    @step = params[:step]
    @setup_data = session[:setup_data] || {}

    case @step
    when 'welcome'
      # Just proceed to next step
      redirect_to setup_wizard_path(step: 'site_settings')
    when 'site_settings'
      if update_site_settings
        redirect_to setup_wizard_path(step: 'admin_user')
      else
        render :site_settings
      end
    when 'admin_user'
      if create_admin_user
        redirect_to setup_wizard_path(step: 'payment_settings')
      else
        render :admin_user
      end
    when 'payment_settings'
      if update_payment_settings
        redirect_to setup_wizard_path(step: 'email_settings')
      else
        render :payment_settings
      end
    when 'email_settings'
      if update_email_settings
        complete_setup
        redirect_to setup_wizard_path(step: 'complete')
      else
        render :email_settings
      end
    else
      redirect_to setup_wizard_path(step: 'welcome')
    end
  end

  private

  def check_setup_completion
    if LmsSetting.get_value('setup_completed', false)
      redirect_to root_path, notice: 'Setup has already been completed.'
    end
  end

  def update_site_settings
    settings_params = params.require(:settings).permit(
      :site_name, :site_description, :default_currency,
      :default_timezone, :enable_registration, :enable_public_courses
    )

    begin
      settings_params.each do |key, value|
        LmsSetting.find_or_create_by!(key: key.to_s) do |setting|
          setting.value = value
          setting.value_type = value.class.name
        end
      end

      # Store in session for later use
      session[:setup_data] ||= {}
      session[:setup_data][:site_settings] = settings_params

      true
    rescue => e
      @error = "Failed to save site settings: #{e.message}"
      false
    end
  end

  def create_admin_user
    user_params = params.require(:user).permit(
      :email, :full_name, :username, :password, :password_confirmation
    )

    begin
      admin = User.new(user_params)
      admin.is_admin = true
      admin.email_verified = true

      if admin.save
        # Assign all LMS roles to admin
        Role.all.each do |role|
          admin.add_role(role.name)
        end

        # Store admin user for session
        session[:setup_data] ||= {}
        session[:setup_data][:admin_user] = { id: admin.id, email: admin.email }

        true
      else
        @error = admin.errors.full_messages.join(', ')
        false
      end
    rescue => e
      @error = "Failed to create admin user: #{e.message}"
      false
    end
  end

  def update_payment_settings
    payment_params = params.require(:payment).permit(
      :enable_payments, :default_gateway, :stripe_publishable_key,
      :stripe_secret_key, :paypal_client_id, :paypal_client_secret
    )

    begin
      payment_params.each do |key, value|
        LmsSetting.find_or_create_by!(key: key.to_s) do |setting|
          setting.value = value
          setting.value_type = value.class.name
        end
      end

      # Create payment gateway if enabled
      if payment_params[:enable_payments] && payment_params[:default_gateway].present?
        PaymentGateway.find_or_create_by!(name: payment_params[:default_gateway]) do |gateway|
          gateway.gateway_type = payment_params[:default_gateway].downcase
          gateway.status = 'active'
          gateway.is_primary = true
          gateway.settings = case payment_params[:default_gateway].downcase
                            when 'stripe'
                              {
                                publishable_key: payment_params[:stripe_publishable_key],
                                secret_key: payment_params[:stripe_secret_key]
                              }
                            when 'paypal'
                              {
                                client_id: payment_params[:paypal_client_id],
                                client_secret: payment_params[:paypal_client_secret]
                              }
                            end
        end
      end

      session[:setup_data] ||= {}
      session[:setup_data][:payment_settings] = payment_params

      true
    rescue => e
      @error = "Failed to save payment settings: #{e.message}"
      false
    end
  end

  def update_email_settings
    email_params = params.require(:email).permit(
      :smtp_host, :smtp_port, :smtp_username, :smtp_password,
      :smtp_tls, :from_email, :from_name, :enable_email_notifications
    )

    begin
      email_params.each do |key, value|
        LmsSetting.find_or_create_by!(key: key.to_s) do |setting|
          setting.value = value
          setting.value_type = value.class.name
        end
      end

      session[:setup_data] ||= {}
      session[:setup_data][:email_settings] = email_params

      true
    rescue => e
      @error = "Failed to save email settings: #{e.message}"
      false
    end
  end

  def complete_setup
    begin
      # Run the installation service
      Lms::InstallService.after_install
      Lms::InstallService.after_sync

      # Mark setup as completed
      LmsSetting.find_or_create_by!(key: 'setup_completed') do |setting|
        setting.value = true
        setting.value_type = 'Boolean'
      end

      # Clear session data
      session.delete(:setup_data)

      # Create a welcome notification for admin
      admin_user = User.find_by(email: session.dig(:setup_data, :admin_user, :email))
      if admin_user
        Notification.create!(
          user: admin_user,
          title: 'Welcome to LMS!',
          message: 'Your Learning Management System has been successfully set up. You can now create courses, manage users, and start building your educational platform.',
          notification_type: 'system'
        )
      end

    rescue => e
      Rails.logger.error "Setup completion failed: #{e.message}"
      @error = "Setup completion failed: #{e.message}"
    end
  end
end