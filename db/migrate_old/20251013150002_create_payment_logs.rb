class CreatePaymentLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_logs do |t|
      t.references :payment, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :status, null: false
      t.json :gateway_response
      t.text :error_message
      t.string :gateway_type
      t.string :transaction_reference
      t.decimal :amount, precision: 10, scale: 2
      t.string :currency
      t.string :ip_address
      t.string :user_agent
      t.text :request_data
      t.text :response_data
      t.integer :retry_count, default: 0
      t.datetime :processed_at
      t.text :notes

      t.timestamps
    end

    add_index :payment_logs, :payment_id unless index_exists?(:payment_logs, :payment_id)
    add_index :payment_logs, :event_type
    add_index :payment_logs, :status
    add_index :payment_logs, :gateway_type
    add_index :payment_logs, :transaction_reference
    add_index :payment_logs, :processed_at
    add_index :payment_logs, [ :payment_id, :event_type ]
    add_index :payment_logs, [ :event_type, :status ]
    add_index :payment_logs, :created_at
  end
end
