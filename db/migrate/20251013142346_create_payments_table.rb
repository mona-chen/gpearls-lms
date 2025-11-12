class CreatePaymentsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :payable, polymorphic: true, null: false, index: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, null: false, default: 'USD'
      t.string :status, null: false, default: 'Pending'
      t.string :payment_method
      t.string :transaction_id
      t.string :gateway_response
      t.datetime :payment_date
      t.datetime :refunded_at
      t.text :refund_reason
      t.text :notes
      t.timestamps
    end

    add_index :payments, [:user_id, :status]
    add_index :payments, [:payable_type, :payable_id], name: 'index_payments_on_payable'
    add_index :payments, :status
    add_index :payments, :payment_date
    add_index :payments, :transaction_id
    add_index :payments, :gateway_response
  end
end
