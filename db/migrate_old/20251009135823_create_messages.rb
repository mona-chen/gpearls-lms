class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :discussion, null: false, foreign_key: true
      t.text :content
      t.string :message_type

      t.timestamps
    end
  end
end
