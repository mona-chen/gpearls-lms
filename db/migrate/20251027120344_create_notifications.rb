class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :subject, null: false
      t.text :email_content
      t.string :document_type
      t.string :document_name
      t.string :notification_type
      t.string :type
      t.boolean :read, default: false
      t.datetime :read_at
      t.string :link
      t.string :from_user

      t.timestamps
    end

    add_index :notifications, [ :user_id, :read ]
    add_index :notifications, [ :user_id, :created_at ]
  end
end
