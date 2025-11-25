class CreateDiscussionTopicsAndReplies < ActiveRecord::Migration[7.2]
  def change
    create_table :discussion_topics do |t|
      t.string :title
      t.text :content
      t.string :reference_doctype
      t.string :reference_docname
      t.string :owner
      t.datetime :creation
      t.datetime :modified
      t.string :modified_by
      t.integer :docstatus, default: 0
      t.integer :idx, default: 0
      t.timestamps
    end

    create_table :discussion_replies do |t|
      t.integer :topic_id
      t.text :reply
      t.string :owner
      t.datetime :creation
      t.datetime :modified
      t.string :modified_by
      t.integer :docstatus, default: 0
      t.integer :idx, default: 0
      t.timestamps
    end

    add_index :discussion_topics, [ :reference_doctype, :reference_docname ]
    add_index :discussion_replies, :topic_id
  end
end
