class CreateDiscussions < ActiveRecord::Migration[7.2]
  def change
    create_table :discussions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string :title
      t.string :content
      t.string :status

      t.timestamps
    end
  end
end
