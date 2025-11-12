class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      t.text :content, null: false
      t.string :message_type, null: false, default: 'text'
      t.references :user, null: false, foreign_key: true
      t.references :discussion, null: false, foreign_key: true
      t.references :parent_message, foreign_key: { to_table: :messages }
      t.timestamps
    end

    add_index :messages, [ :discussion_id, :created_at ] unless index_exists?(:messages, [ :discussion_id, :created_at ])
    add_index :messages, :parent_message_id unless index_exists?(:messages, :parent_message_id)
  end
end
