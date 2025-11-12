# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Settings::BrandingService, type: :service do
  describe '.call' do
    it 'returns branding information with proper structure' do
      result = described_class.call

      expect(result).to be_a(Hash)
      expect(result['data']).to be_a(Hash)
      expect(result['data']).to have_key(:app_name)
      expect(result['data']).to have_key(:app_logo_url)
      expect(result['data']).to have_key(:favicon_url)
    end

    it 'returns default branding values when no settings exist' do
      result = described_class.call

      expect(result['data'][:app_name]).to eq('LMS')
      expect(result['data'][:footer_text]).to eq('© 2025 LMS. All rights reserved.')
      expect(result['data'][:allow_password_reset]).to be true
    end

    it 'loads branding settings from LmsSetting model' do
      # Create test settings
      LmsSetting.create!(key: 'site_name', value: 'Custom LMS', fieldtype: 'Data')
      LmsSetting.create!(key: 'logo_url', value: '/custom-logo.png', fieldtype: 'Data')
      LmsSetting.create!(key: 'hide_login', value: '1', fieldtype: 'Check')

      result = described_class.call

      expect(result['data'][:app_name]).to eq('Custom LMS')
      expect(result['data'][:app_logo_url]).to eq('/custom-logo.png')
      expect(result['data'][:hide_login]).to be true
    end

    it 'handles boolean settings correctly' do
      LmsSetting.create!(key: 'enable_2fa', value: '1', fieldtype: 'Check')
      LmsSetting.create!(key: 'disable_signup', value: '0', fieldtype: 'Check')

      result = described_class.call

      expect(result['data'][:enable_2fa]).to be true
      expect(result['data'][:disable_signup]).to be false
    end

    it 'returns all required branding fields' do
      result = described_class.call

      required_fields = [
        :app_name, :app_logo, :app_logo_url, :favicon, :favicon_url,
        :html_css, :splash_image, :splash_image_url, :onboarding_video,
        :footer_logo, :footer_logo_url, :footer_text, :hide_login,
        :signup_form, :parent_app, :integration_request_service,
        :integration_request_key, :restrict_user_domain, :allowed_user_domains,
        :restrict_signup_by_role, :allowed_signup_roles, :disable_signup,
        :enable_signup_on_frappe_signup_form, :enable_2fa, :allow_password_reset,
        :enable_google_auth, :enable_facebook_auth, :enable_frappe_auth,
        :enable_office365_auth, :enable_github_auth
      ]

      required_fields.each do |field|
        expect(result['data']).to have_key(field)
      end
    end
  end
end
