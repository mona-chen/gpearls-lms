class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      # Users specific fields (based on Frappe User doctype)
      t.string :email, null: false                     # User email (primary login)
      t.string :first_name, null: false                # First name
      t.string :last_name, null: false                 # Last name
      t.string :full_name, null: false                 # Full name (computed)
      t.string :username, null: false                  # Unique username
      t.string :password_digest, null: false           # Encrypted password
      t.string :role, default: "LMS Student"          # User role (Course Creator, Moderator, Batch Evaluator, LMS Student)
      t.string :status, default: "Active"              # User status (Active, Disabled, Pending)
      t.string :phone, null: true                      # Phone number
      t.string :mobile_no, null: true                  # Mobile number
      t.date :birth_date, null: true                   # Birth date
      t.string :gender, null: true                     # Gender
      t.string :bio, null: true                        # Biography/About
      t.string :profile_image, null: true              # Profile image URL
      t.string :timezone, default: "UTC"               # User timezone
      t.string :language, default: "English"           # Preferred language
      t.string :country, null: true                    # Country
      t.string :city, null: true                       # City
      t.text :address, null: true                      # Address
      t.string :postal_code, null: true                # Postal code
      t.string :company, null: true                    # Company/Organization
      t.string :job_title, null: true                  # Job title
      t.string :department, null: true                 # Department
      t.string :website, null: true                    # Personal website
      t.string :linkedin_profile, null: true           # LinkedIn profile URL
      t.string :twitter_profile, null: true            # Twitter profile URL
      t.boolean :email_verified, default: false        # Email verification status
      t.datetime :email_verified_at, null: true        # Email verification timestamp
      t.string :verification_token, null: true         # Email verification token
      t.datetime :last_login_at, null: true            # Last login timestamp
      t.string :last_login_ip, null: true              # Last login IP address
      t.datetime :current_login_at, null: true         # Current login timestamp
      t.string :current_login_ip, null: true           # Current login IP address
      t.integer :login_count, default: 0               # Number of logins
      t.boolean :receive_email_notifications, default: true  # Email notification preferences
      t.boolean :receive_sms_notifications, default: false   # SMS notification preferences
      t.text :notification_preferences                 # Notification settings (JSON)
      t.text :preferences                              # User preferences (JSON)
      t.text :skills                                    # User skills (JSON array)
      t.text :interests                                # User interests (JSON array)
      t.decimal :rating, precision: 3, scale: 2, default: 0.00  # User rating (if instructor)
      t.integer :reviews_count, default: 0             # Number of reviews received
      t.integer :courses_created_count, default: 0     # Number of courses created
      t.integer :students_taught_count, default: 0     # Number of students taught
      t.text :social_links                             # Social media links (JSON)
      t.text :custom_fields                             # Custom fields (JSON)
      t.datetime :deactivated_at, null: true           # Account deactivation timestamp
      t.string :deactivation_reason, null: true        # Reason for deactivation
      t.boolean :is_mentor, default: false             # Whether user is a mentor
      t.boolean :is_instructor, default: false         # Whether user is an instructor
      t.boolean :is_admin, default: false              # Whether user is admin

      t.timestamps
    end

    # Add indexes for performance and common queries
    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
    add_index :users, :first_name
    add_index :users, :last_name
    add_index :users, :full_name
    add_index :users, :role
    add_index :users, :status
    add_index :users, :phone
    add_index :users, :country
    add_index :users, :city
    add_index :users, :company
    add_index :users, :email_verified
    add_index :users, :last_login_at
    add_index :users, :login_count
    add_index :users, :rating
    add_index :users, :courses_created_count
    add_index :users, :students_taught_count
    add_index :users, :is_mentor
    add_index :users, :is_instructor
    add_index :users, :is_admin
    add_index :users, [ :role, :status ]
    add_index :users, [ :status, :last_login_at ]
    add_index :users, [ :is_instructor, :rating ]
    add_index :users, [ :country, :city ]
  end
end
