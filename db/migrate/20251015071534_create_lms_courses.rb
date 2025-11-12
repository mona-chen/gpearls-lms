class CreateLmsCourses < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_courses do |t|
      # LMS Courses specific fields (based on Frappe Course doctype)
      t.string :title, null: false                     # Course title (primary field)
      t.text :description                              # Course description
      t.string :short_introduction, null: true         # Short introduction text
      t.string :category, null: true                   # Course category
      t.string :status, default: "Draft"               # Course status (Draft, Published, Archived)
      t.string :video_link, null: true                 # Introduction video URL
      t.string :image, null: true                      # Course image/thumbnail
      t.text :tags, null: true                         # Course tags (JSON array)
      t.decimal :price, precision: 10, scale: 2, default: 0.00  # Course price
      t.string :currency, default: "USD"               # Currency code
      t.boolean :published, default: false             # Whether course is published
      t.boolean :featured, default: false              # Whether course is featured
      t.boolean :allow_self_enrollment, default: true  # Allow self enrollment
      t.boolean :require_approval, default: false      # Require approval for enrollment
      t.integer :max_students, default: 0              # Maximum students (0 = unlimited)
      t.integer :duration_hours, default: 0            # Course duration in hours
      t.string :difficulty_level, default: "Beginner"  # Difficulty level
      t.string :language, default: "English"           # Course language
      t.text :prerequisites                            # Prerequisites (JSON)
      t.text :learning_objectives                      # Learning objectives (JSON)
      t.text :target_audience                          # Target audience
      t.string :instructor_name, null: true            # Instructor name (for display)
      t.references :instructor, foreign_key: { to_table: :users }, null: true  # Instructor user reference
      t.integer :enrollments_count, default: 0         # Number of enrollments
      t.decimal :rating, precision: 3, scale: 2, default: 0.00  # Average rating
      t.integer :reviews_count, default: 0             # Number of reviews
      t.datetime :published_at, null: true             # Publication date
      t.datetime :last_updated_on, null: true          # Last content update
      t.text :metadata                                 # Additional metadata (JSON)
      t.string :course_code, null: true                # Unique course code
      t.boolean :certificate_enabled, default: false   # Enable certificates
      t.text :seo_title                                # SEO title
      t.text :seo_description                          # SEO description
      t.string :slug, null: true                       # URL-friendly slug
      t.integer :sort_order, default: 0                # Sort order for listings

      t.timestamps
    end

    # Add indexes for performance and common queries
    add_index :lms_courses, :title
    add_index :lms_courses, :status
    add_index :lms_courses, :category
    add_index :lms_courses, :published
    add_index :lms_courses, :featured
    # instructor_id index automatically created by references helper
    add_index :lms_courses, :price
    add_index :lms_courses, :difficulty_level
    add_index :lms_courses, :language
    add_index :lms_courses, :enrollments_count
    add_index :lms_courses, :rating
    add_index :lms_courses, :published_at
    add_index :lms_courses, :course_code, unique: true
    add_index :lms_courses, :slug, unique: true
    add_index :lms_courses, :sort_order
    add_index :lms_courses, [:published, :featured]
    add_index :lms_courses, [:category, :published]
  end
end
