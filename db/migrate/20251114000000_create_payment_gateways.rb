class CreatePaymentGateways < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_gateways do |t|
      t.string :name, null: false
      t.string :gateway_type, null: false
      t.string :status, null: false, default: 'inactive'
      t.json :settings, null: false, default: {}
      t.boolean :is_primary, default: false
      t.timestamps
    end

    add_index :payment_gateways, :name, unique: true
    add_index :payment_gateways, :gateway_type
    add_index :payment_gateways, :status
    add_index :payment_gateways, :is_primary
  end
end
