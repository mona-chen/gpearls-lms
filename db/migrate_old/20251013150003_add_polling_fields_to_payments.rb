class AddPollingFieldsToPayments < ActiveRecord::Migration[7.0]
  def change
    add_column :payments, :poll_count, :integer, default: 0
    add_column :payments, :last_polled_at, :datetime
    add_column :payments, :polling_expires_at, :datetime
    add_column :payments, :auto_verification_enabled, :boolean, default: true

    # Add indexes
    add_index :payments, :poll_count
    add_index :payments, :last_polled_at
    add_index :payments, :polling_expires_at
    add_index :payments, :auto_verification_enabled
  end
end