Rails.application.routes.draw do
  get "dashboard", to: "dashboard#index"
  devise_for :users
  devise_for :users, skip: [ :sessions, :registrations ]

  # Session-based authentication routes (Frappe compatible)
  get "login", to: "sessions#new"
  get "signup", to: "sessions#signup"
  post "login", to: "sessions#create"
  post "logout", to: "sessions#destroy"
  match "login", to: "sessions#handle_options", via: [ :options ]

  # API authentication routes
  post "api/login", to: "api/authentication#login"
  post "api/logout", to: "api/authentication#logout"
  post "api/signup", to: "api/authentication#signup"

  # User management
  get "api/user", to: "api/users#get_user_info"
  get "api/users", to: "api/users#get_all_users"
  get "api/members", to: "api/users#get_members"

  # Generic Frappe-style API endpoints for frontend compatibility
  post "api/method/*method_path", to: "api/compatibility#handle_method", constraints: { method_path: /.+/ }

  # Courses
  get "api/courses", to: "api/courses#index"
  get "api/courses/:course", to: "api/courses#show"
  post "api/courses", to: "api/courses#create"
  put "api/courses/:course", to: "api/courses#update"
  delete "api/courses/:course", to: "api/courses#destroy"

  # Course outline and lessons
  get "api/course-outline/:course", to: "api/course_outline#show"
  get "api/lesson/:course/:chapter/:lesson", to: "api/lessons#show"
  post "api/lesson-progress/:course/:chapter/:lesson", to: "api/lessons#update_progress"

  # Quizzes
  get "api/quizzes", to: "api/quizzes#index"
  get "api/quiz/:quiz_id", to: "api/quizzes#get_quiz_details"
  post "api/quiz/submit/:quiz_id", to: "api/quizzes#submit"
  get "api/quiz/attempts/:quiz_id", to: "api/quizzes#get_quiz_attempts"

  # Batches
  get "api/batches", to: "api/batches#index"
  get "api/batches/:batch", to: "api/batches#show"
  post "api/batch/enroll/:batch", to: "api/batches#enroll"

  # Cohorts
  get "api/cohorts", to: "api/cohorts#index"
  get "api/cohorts/:id", to: "api/cohorts#show"
  post "api/cohorts", to: "api/cohorts#create"
  put "api/cohorts/:id", to: "api/cohorts#update"
  delete "api/cohorts/:id", to: "api/cohorts#destroy"
  post "api/cohorts/:id/join", to: "api/cohorts#join"
  delete "api/cohorts/:id/leave", to: "api/cohorts#leave"
  get "api/cohorts/:id/subgroups", to: "api/cohorts#subgroups"
  post "api/cohorts/:id/subgroups", to: "api/cohorts#create_subgroup"
  get "api/cohorts/:id/join-requests", to: "api/cohorts#join_requests"
  post "api/cohorts/:id/join-requests/:request_id/approve", to: "api/cohorts#approve_join_request"
  post "api/cohorts/:id/join-requests/:request_id/reject", to: "api/cohorts#reject_join_request"
  post "api/cohorts/:id/add-mentor", to: "api/cohorts#add_mentor"
  delete "api/cohorts/:id/remove-mentor", to: "api/cohorts#remove_mentor"
  post "api/cohorts/:id/add-staff", to: "api/cohorts#add_staff"
  delete "api/cohorts/:id/remove-staff", to: "api/cohorts#remove_staff"
  get "api/cohorts/:id/statistics", to: "api/cohorts#statistics"
  get "api/cohorts/:id/members", to: "api/cohorts#members"
  get "api/cohorts/my-enrollments", to: "api/cohorts#my_enrollments"

  # Certificates
  post "api/certificate/:course", to: "api/certificates#create"
  get "api/evaluation-details/:course", to: "api/certificates#evaluation_details"
  post "api/save-evaluation", to: "api/certificates#save_evaluation"

  # Files
  post "api/upload", to: "api/files#upload"
  get "api/file-info", to: "api/files#info"

  # Statistics
  get "api/chart-details", to: "api/statistics#chart_details"
  get "api/course-progress-distribution/:course", to: "api/statistics#course_progress_distribution"
  get "api/heatmap-data", to: "api/statistics#heatmap_data"

  # Settings
  get "api/settings", to: "api/settings#index"
  get "api/sidebar-settings", to: "api/settings#sidebar_settings"
  get "api/lms-setting", to: "api/settings#lms_setting"
  get "api/branding", to: "api/settings#branding"

  # Utility endpoints
  get "api/categories/:doctype", to: "api/utilities#categories"
  get "api/count/:doctype", to: "api/utilities#count"
  get "api/members", to: "api/users#get_members"

  # PWA Manifest
  get "api/pwa-manifest", to: "api/utilities#pwa_manifest"

  # Notifications
  get "api/notifications", to: "api/notifications#get_notifications"
  post "api/notification/mark-as-read/:notification_id", to: "api/notifications#mark_as_read"
  post "api/notifications/mark-all-as-read", to: "api/notifications#mark_all_as_read"

  # Job Opportunities
  get "api/job-opportunities", to: "api/job_opportunities#get_job_opportunities"
  get "api/job/:job_id", to: "api/job_opportunities#get_job_details"
  post "api/job/apply/:job_id", to: "api/job_opportunities#apply_job"

  # Workflows
  get "api/workflow-actions/:document_type/:document_name", to: "api/workflows#get_workflow_actions"
  post "api/workflow-action/:document_type/:document_name", to: "api/workflows#apply_workflow_action"

  # Onboarding
  get "api/onboarding/status", to: "api/onboarding#status"
  get "api/onboarding/first-course", to: "api/onboarding#first_course"
  get "api/onboarding/first-batch", to: "api/onboarding#first_batch"
  post "api/onboarding/handle_method", to: "api/onboarding#handle_method"

  # Payments
  post "api/payments/initialize", to: "api/payments#initialize_payment"
  get "api/payments", to: "api/payments#index"
  get "api/payments/:id", to: "api/payments#show"
  post "api/payments/:id/verify", to: "api/payments#verify"
  post "api/payments/:id/refund", to: "api/payments#refund"
  post "api/payments/callback/paystack", to: "api/payments#paystack_callback"
  get "api/payments/gateways", to: "api/payments#gateways"
  post "api/payments/methods", to: "api/payments#add_payment_method"
  get "api/payments/methods", to: "api/payments#payment_methods"
  delete "api/payments/methods/:id", to: "api/payments#remove_payment_method"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
