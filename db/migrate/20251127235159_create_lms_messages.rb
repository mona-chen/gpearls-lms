class CreateLmsMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_messages do |t|
      t.string :topic
      t.text :reply
      t.references :author, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.boolean :is_pinned
      t.boolean :is_featured

      t.timestamps
    end
  end
end
