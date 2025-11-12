class CreateLiveClasses < ActiveRecord::Migration[7.2]
  def change
    return if table_exists?(:live_classes)

    create_table :live_classes do |t|
      t.string :name
      t.string :title
      t.text :description
      t.date :date
      t.time :time
      t.string :duration
      t.string :attendees
      t.string :start_url
      t.string :join_url
      t.string :owner
      t.references :batch, null: false, foreign_key: true
      t.references :course, foreign_key: true
      t.references :instructor, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :live_classes, :date unless index_exists?(:live_classes, :date)
    add_index :live_classes, :batch_id unless index_exists?(:live_classes, :batch_id)
    add_index :live_classes, :course_id unless index_exists?(:live_classes, :course_id)
    add_index :live_classes, :instructor_id unless index_exists?(:live_classes, :instructor_id)
  end
end
