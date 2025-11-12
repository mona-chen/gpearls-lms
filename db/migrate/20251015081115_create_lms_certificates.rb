class CreateLmsCertificates < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_certificates do |t|
      # LMS Certificates specific fields (based on Frappe Certificate doctype)
      t.string :name, null: false                        # Certificate name/number (primary field)
      t.references :student, null: false, foreign_key: { to_table: :users }  # Student who received certificate
      t.references :course, foreign_key: { to_table: :lms_courses }, null: true  # Related course
      t.references :batch, foreign_key: { to_table: :lms_batches }, null: true  # Related batch
      t.references :program, foreign_key: { to_table: :lms_programs }, null: true  # Related program
      t.references :quiz, foreign_key: { to_table: :lms_quizzes }, null: true  # Related quiz (if quiz certificate)
      t.references :assignment, foreign_key: { to_table: :lms_assignments }, null: true  # Related assignment
      t.string :certificate_type, default: "Course"       # Certificate type (Course, Program, Quiz, Assignment, Badge)
      t.string :status, default: "Draft"                  # Certificate status (Draft, Issued, Revoked, Expired)
      t.string :certificate_code, null: false             # Unique certificate code
      t.string :certificate_title, null: false            # Certificate title
      t.text :description                                 # Certificate description
      t.string :template_name, null: true                 # Certificate template used
      t.text :template_data                               # Template customization data (JSON)
      t.datetime :issue_date, null: true                  # Certificate issue date
      t.datetime :expiry_date, null: true                 # Certificate expiry date
      t.boolean :has_expiry, default: false               # Whether certificate expires
      t.integer :validity_days, default: 0                # Validity period in days
      t.decimal :grade_obtained, precision: 5, scale: 2, null: true  # Grade obtained (if applicable)
      t.decimal :percentage_obtained, precision: 5, scale: 2, null: true  # Percentage obtained
      t.string :grade_achieved, null: true                # Grade achieved text
      t.string :completion_status, default: "Completed"   # Completion status
      t.text :achievements                                # Achievements/recognitions (JSON)
      t.text :skills_attained                             # Skills attained (JSON)
      t.string :instructor_name, null: true               # Instructor name on certificate
      t.string :instructor_signature, null: true          # Instructor signature URL
      t.string :authority_name, null: true                # Issuing authority name
      t.string :authority_signature, null: true           # Authority signature URL
      t.string :authority_seal, null: true                # Authority seal/logo URL
      t.text :additional_signees                          # Additional signees (JSON)
      t.string :certificate_url, null: true               # Public certificate URL
      t.string :verification_code, null: true             # Verification code
      t.boolean :publicly_accessible, default: false      # Whether certificate is publicly accessible
      t.integer :verification_count, default: 0           # Number of times verified
      t.datetime :last_verified_at, null: true            # Last verification timestamp
      t.text :metadata                                    # Additional metadata (JSON)
      t.references :issued_by, foreign_key: { to_table: :users }, null: true  # Who issued the certificate
      t.datetime :revoked_at, null: true                  # Revocation timestamp
      t.string :revocation_reason, null: true             # Reason for revocation
      t.references :revoked_by, foreign_key: { to_table: :users }, null: true  # Who revoked the certificate
      t.text :revocation_notes                            # Revocation notes
      t.boolean :digital_signature, default: false        # Whether certificate has digital signature
      t.text :digital_signature_data                      # Digital signature data (JSON)
      t.string :blockchain_hash, null: true               # Blockchain verification hash
      t.text :custom_fields                               # Custom fields (JSON)

      t.timestamps
    end

    # Add indexes for performance and common queries
    add_index :lms_certificates, :name, unique: true
    # student_id, course_id, batch_id, program_id, quiz_id, assignment_id indexes automatically created by references helpers
    add_index :lms_certificates, :certificate_type
    add_index :lms_certificates, :status
    add_index :lms_certificates, :certificate_code, unique: true
    add_index :lms_certificates, :verification_code, unique: true
    add_index :lms_certificates, :issue_date
    add_index :lms_certificates, :expiry_date
    add_index :lms_certificates, :publicly_accessible
    add_index :lms_certificates, :verification_count
    # issued_by_id index automatically created by references helper
    add_index :lms_certificates, :revoked_at
    add_index :lms_certificates, [:student_id, :certificate_type]
    add_index :lms_certificates, [:course_id, :student_id]
    add_index :lms_certificates, [:certificate_type, :status]
    add_index :lms_certificates, [:status, :issue_date]
    add_index :lms_certificates, [:student_id, :status]
    add_index :lms_certificates, [:publicly_accessible, :verification_count]
  end
end
