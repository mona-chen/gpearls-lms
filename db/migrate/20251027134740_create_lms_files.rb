class CreateLmsFiles < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_files do |t|
      t.string :file_name, null: false
      t.string :file_url, null: false
      t.string :file_type
      t.integer :file_size
      t.string :content_hash
      t.boolean :is_private, default: false
      t.boolean :is_folder, default: false
      t.integer :folder_id
      t.boolean :is_home_folder, default: false
      t.boolean :is_attachments_folder, default: false
      t.string :attached_to_doctype
      t.string :attached_to_name
      t.string :attached_to_field
      t.integer :uploaded_by_id
      t.datetime :uploaded_at

      t.timestamps
    end

    add_index :lms_files, [ :attached_to_doctype, :attached_to_name ]
    add_index :lms_files, :uploaded_by_id
    add_index :lms_files, :file_url
  end
end
