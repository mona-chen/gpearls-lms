class CreateLmsCourseReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_course_reviews do |t|
      # Frappe standard fields
      t.string :name, null: false
      t.string :owner, null: false
      t.datetime :creation, null: false
      t.datetime :modified, null: false
      t.string :modified_by, null: false
      t.string :docstatus, default: "0"
      t.string :parent, null: true
      t.string :parenttype, null: true
      t.string :parentfield, null: true
      t.integer :idx, null: true

      # Exact Frappe field structure from lms_course_review.json
      t.text :review                         # Small Text field
      t.integer :rating, null: false         # Rating field, reqd: 1
      t.string :course, null: false          # Link to LMS Course, reqd: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_course_reviews, :course
    add_index :lms_course_reviews, :rating
    add_index :lms_course_reviews, :creation
    add_index :lms_course_reviews, :modified
    add_index :lms_course_reviews, [ :course, :rating ], name: 'index_course_review_on_course_and_rating'
    add_index :lms_course_reviews, [ :course, :creation ], name: 'index_course_review_on_course_and_creation'

    # Add foreign key constraints
    add_foreign_key :lms_course_reviews, :lms_courses, column: :course
  end
end
