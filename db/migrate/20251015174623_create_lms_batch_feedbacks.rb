class CreateLmsBatchFeedbacks < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_batch_feedbacks do |t|
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

      # Exact Frappe field structure from lms_batch_feedback.json
      t.string :member, null: false                      # Link to User, reqd: 1
      t.string :member_name, null: false                 # Data, fetched from member.full_name
      t.string :member_image                             # Attach Image, fetched from member.user_image
      t.string :batch, null: false                       # Link to LMS Batch, reqd: 1
      t.text :feedback, null: false                      # Small Text, reqd: 1
      t.integer :content                                 # Rating field
      t.integer :instructors                             # Rating field
      t.integer :value                                   # Rating field

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_batch_feedbacks, :member
    add_index :lms_batch_feedbacks, :batch
    add_index :lms_batch_feedbacks, :content
    add_index :lms_batch_feedbacks, :instructors
    add_index :lms_batch_feedbacks, :value
    add_index :lms_batch_feedbacks, :creation
    add_index :lms_batch_feedbacks, :modified
    add_index :lms_batch_feedbacks, [:member, :batch], unique: true, name: 'index_batch_feedback_on_member_and_batch'

    # Add foreign key constraints
    add_foreign_key :lms_batch_feedbacks, :users, column: :member
    add_foreign_key :lms_batch_feedbacks, :lms_batches, column: :batch
  end
end
