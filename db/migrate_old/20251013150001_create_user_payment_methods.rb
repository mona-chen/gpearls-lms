class CreateUserPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    create_table :user_payment_methods do |t|
      t.references :user, null: false, foreign_key: true
      t.references :payment_gateway, null: false, foreign_key: true
      t.string :method_type, null: false
      t.string :status, null: false, default: 'active'
      t.string :customer_code
      t.string :customer_id
      t.string :authorization_code
      t.string :last4
      t.string :exp_month
      t.string :exp_year
      t.string :card_type
      t.string :bank_name
      t.string :account_name
      t.string :account_number_last4
      t.json :gateway_data
      t.boolean :is_default, default: false
      t.datetime :expires_at
      t.text :notes

      t.timestamps
    end

    add_index :user_payment_methods, [:user_id, :status]
    add_index :user_payment_methods, [:user_id, :method_type]
    add_index :user_payment_methods, :payment_gateway_id unless index_exists?(:user_payment_methods, :payment_gateway_id)
    add_index :user_payment_methods, :customer_code
    add_index :user_payment_methods, :authorization_code
    add_index :user_payment_methods, :is_default
    add_index :user_payment_methods, :expires_at
  end
end
