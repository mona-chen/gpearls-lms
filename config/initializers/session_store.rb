Rails.application.config.session_store :cookie_store, key: "_lms-api_session"

Rails.application.config.middleware.use ActionDispatch::Cookies
Rails.application.config.middleware.use ActionDispatch::Session::CookieStore
