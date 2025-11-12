class CreateDiscussions < ActiveRecord::Migration[7.2]
  def change
    create_table :discussions do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :status, null: false, default: 'open'
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.timestamps
    end

    add_index :discussions, [ :course_id, :status ]
    add_index :discussions, :created_at
  end
end
