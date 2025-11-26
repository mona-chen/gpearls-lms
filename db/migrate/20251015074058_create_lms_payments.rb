class CreateLmsPayments < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_payments do |t|
      # LMS Payments specific fields (based on Frappe Payment doctype)
      t.string :payment_number, null: false                # Unique payment number
      t.references :student, null: false, foreign_key: { to_table: :users }  # Student who made payment
      t.references :enrollment, foreign_key: { to_table: :lms_enrollments }, null: true  # Related enrollment
      t.references :course, foreign_key: { to_table: :lms_courses }, null: true  # Related course
      t.references :batch, foreign_key: { to_table: :lms_batches }, null: true  # Related batch
      t.references :program, foreign_key: { to_table: :lms_programs }, null: true  # Related program
      t.string :payment_type, default: "Course Enrollment"  # Payment type (Course Enrollment, Program Fee, Certificate, etc.)
      t.decimal :amount, precision: 10, scale: 2, null: false  # Payment amount
      t.string :currency, default: "USD"                   # Currency code
      t.string :status, default: "Pending"                 # Payment status (Pending, Paid, Failed, Refunded, Partial)
      t.string :payment_method, null: true                 # Payment method (Credit Card, PayPal, Bank Transfer, etc.)
      t.string :gateway, null: true                        # Payment gateway used
      t.string :transaction_id, null: true                 # Gateway transaction ID
      t.string :gateway_response, null: true               # Gateway response code
      t.text :gateway_response_data                        # Full gateway response (JSON)
      t.datetime :payment_date, null: true                 # Date payment was processed
      t.datetime :due_date, null: true                     # Payment due date
      t.decimal :amount_paid, precision: 10, scale: 2, default: 0.00  # Amount actually paid
      t.decimal :balance_amount, precision: 10, scale: 2, default: 0.00  # Remaining balance
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0.00  # Tax amount
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0.00  # Discount amount
      t.string :discount_code, null: true                  # Discount code used
      t.references :discount_applied, foreign_key: { to_table: :lms_badges }, null: true  # Discount reference
      t.string :billing_name, null: true                   # Billing name
      t.string :billing_email, null: true                  # Billing email
      t.string :billing_phone, null: true                  # Billing phone
      t.text :billing_address                              # Billing address
      t.string :billing_city, null: true                   # Billing city
      t.string :billing_state, null: true                  # Billing state
      t.string :billing_country, null: true                # Billing country
      t.string :billing_postal_code, null: true            # Billing postal code
      t.string :payment_description, null: true            # Payment description
      t.text :payment_notes                                # Additional payment notes
      t.references :processed_by, foreign_key: { to_table: :users }, null: true  # Who processed payment
      t.text :refund_details                               # Refund details (JSON)
      t.decimal :refund_amount, precision: 10, scale: 2, default: 0.00  # Refund amount
      t.string :refund_reason, null: true                  # Reason for refund
      t.datetime :refund_date, null: true                  # Refund date
      t.references :refund_processed_by, foreign_key: { to_table: :users }, null: true  # Who processed refund
      t.string :invoice_number, null: true                 # Invoice number
      t.datetime :invoice_date, null: true                 # Invoice date
      t.text :invoice_details                              # Invoice details (JSON)
      t.boolean :recurring_payment, default: false         # Whether this is a recurring payment
      t.string :recurring_frequency, null: true            # Recurring frequency (Monthly, Yearly, etc.)
      t.datetime :next_payment_date, null: true            # Next payment date for recurring
      t.text :custom_fields                                # Custom fields (JSON)

      t.timestamps
    end

    # Add indexes for performance and common queries
    add_index :lms_payments, :payment_number, unique: true
    # student_id, enrollment_id, course_id, batch_id, program_id indexes automatically created by references helpers
    add_index :lms_payments, :payment_type
    add_index :lms_payments, :amount
    add_index :lms_payments, :currency
    add_index :lms_payments, :status
    add_index :lms_payments, :payment_method
    add_index :lms_payments, :gateway
    add_index :lms_payments, :transaction_id
    add_index :lms_payments, :payment_date
    add_index :lms_payments, :due_date
    add_index :lms_payments, :amount_paid
    add_index :lms_payments, :balance_amount
    add_index :lms_payments, :discount_code
    add_index :lms_payments, :invoice_number
    add_index :lms_payments, :refund_amount
    # processed_by_id index automatically created by references helper
    add_index :lms_payments, [ :student_id, :status ]
    add_index :lms_payments, [ :status, :payment_date ]
    add_index :lms_payments, [ :payment_type, :status ]
    add_index :lms_payments, [ :gateway, :status ]
    add_index :lms_payments, [ :course_id, :student_id ]
    add_index :lms_payments, [ :enrollment_id, :student_id ]
  end
end
