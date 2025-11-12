module Settings
  class BrandingService
    def self.call
      new.call
    end

    def initialize
      # Load branding settings from LmsSetting model
    end

    def call
      {
        "data" => {
          app_name: fetch_app_name,
          app_logo: fetch_app_logo,
          app_logo_url: fetch_app_logo_url,
          favicon: fetch_favicon,
          favicon_url: fetch_favicon_url,
          html_css: fetch_html_css,
          splash_image: fetch_splash_image,
          splash_image_url: fetch_splash_image_url,
          onboarding_video: fetch_onboarding_video,
          footer_logo: fetch_footer_logo,
          footer_logo_url: fetch_footer_logo_url,
          footer_text: fetch_footer_text,
          hide_login: fetch_hide_login,
          signup_form: fetch_signup_form,
          parent_app: fetch_parent_app,
          integration_request_service: fetch_integration_request_service,
          integration_request_key: fetch_integration_request_key,
          restrict_user_domain: fetch_restrict_user_domain,
          allowed_user_domains: fetch_allowed_user_domains,
          restrict_signup_by_role: fetch_restrict_signup_by_role,
          allowed_signup_roles: fetch_allowed_signup_roles,
          disable_signup: fetch_disable_signup,
          enable_signup_on_frappe_signup_form: fetch_enable_signup_on_frappe_signup_form,
          enable_2fa: fetch_enable_2fa,
          allow_password_reset: fetch_allow_password_reset,
          enable_google_auth: fetch_enable_google_auth,
          enable_facebook_auth: fetch_enable_facebook_auth,
          enable_frappe_auth: fetch_enable_frappe_auth,
          enable_office365_auth: fetch_enable_office365_auth,
          enable_github_auth: fetch_enable_github_auth
        }
      }
    end

    private

    def fetch_app_name
      "LMS"
    end

    def fetch_app_logo
      nil
    end

    def fetch_app_logo_url
      "/assets/lms/images/logo.svg"
    end

    def fetch_favicon
      nil
    end

    def fetch_favicon_url
      "/assets/lms/images/favicon.ico"
    end

    def fetch_html_css
      ""
    end

    def fetch_splash_image
      nil
    end

    def fetch_splash_image_url
      nil
    end

    def fetch_onboarding_video
      nil
    end

    def fetch_footer_logo
      nil
    end

    def fetch_footer_logo_url
      nil
    end

    def fetch_footer_text
      "© 2025 LMS. All rights reserved."
    end

    def fetch_hide_login
      false
    end

    def fetch_signup_form
      false
    end

    def fetch_parent_app
      nil
    end

    def fetch_integration_request_service
      nil
    end

    def fetch_integration_request_key
      nil
    end

    def fetch_restrict_user_domain
      false
    end

    def fetch_allowed_user_domains
      ""
    end

    def fetch_restrict_signup_by_role
      false
    end

    def fetch_allowed_signup_roles
      ""
    end

    def fetch_disable_signup
      false
    end

    def fetch_enable_signup_on_frappe_signup_form
      false
    end

    def fetch_enable_2fa
      false
    end

    def fetch_allow_password_reset
      true
    end

    def fetch_enable_google_auth
      false
    end

    def fetch_enable_facebook_auth
      false
    end

    def fetch_enable_frappe_auth
      false
    end

    def fetch_enable_office365_auth
      false
    end

    def fetch_enable_github_auth
      false
    end
  end
end
