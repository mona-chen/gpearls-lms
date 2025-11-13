class CreateScormPackages < ActiveRecord::Migration[7.0]
  def change
    create_table :scorm_packages do |t|
      t.references :course_lesson, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :manifest_file
      t.text :launch_file
      t.string :version
      t.integer :status, default: 0
      t.text :manifest_content
      t.text :extracted_path
      t.text :error_message
      t.json :metadata
      t.datetime :extracted_at
      
      t.timestamps
    end
    
    add_index :scorm_packages, [:course_lesson_id], name: 'index_scorm_packages_on_lesson'
    add_index :scorm_packages, [:status], name: 'index_scorm_packages_on_status'
    add_index :scorm_packages, [:uploaded_by_id], name: 'index_scorm_packages_on_uploader'
  end
end