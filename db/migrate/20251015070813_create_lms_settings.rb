class CreateLmsSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_settings do |t|
      # LMS Settings specific fields (based on Frappe LMS Settings doctype)
      t.string :enable_learner_dashboard, default: "1"      # Enable Learner Dashboard
      t.string :enable_moderator_dashboard, default: "1"    # Enable Moderator Dashboard
      t.string :enable_course_creation, default: "1"        # Enable Course Creation
      t.string :default_course_category                   # Default Course Category
      t.string :enable_certificates, default: "1"          # Enable Certificates
      t.string :enable_badges, default: "1"               # Enable Badges
      t.string :enable_discussions, default: "1"          # Enable Discussions
      t.string :enable_live_classes, default: "1"         # Enable Live Classes
      t.string :enable_assignments, default: "1"          # Enable Assignments
      t.string :enable_quizzes, default: "1"              # Enable Quizzes
      t.string :enable_programs, default: "1"             # Enable Programs
      t.string :enable_cohorts, default: "1"              # Enable Cohorts
      t.string :zoom_api_key                             # Zoom API Key
      t.text :zoom_api_secret                            # Zoom API Secret
      t.string :default_currency                         # Default Currency
      t.string :payment_gateway_settings                 # Payment Gateway Settings (JSON)

      t.timestamps
    end

    # Add indexes for frequently queried settings
    add_index :lms_settings, :enable_learner_dashboard
    add_index :lms_settings, :enable_course_creation
    add_index :lms_settings, :default_course_category
  end
end
