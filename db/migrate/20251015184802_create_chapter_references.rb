class CreateChapterReferences < ActiveRecord::Migration[7.0]
  def change
    create_table :chapter_references do |t|
      # Frappe standard fields
      t.string :name, null: false
      t.string :owner, null: false
      t.datetime :creation, null: false
      t.datetime :modified, null: false
      t.string :modified_by, null: false
      t.string :docstatus, default: "0"
      t.string :parent, null: true
      t.string :parenttype, null: true
      t.string :parentfield, null: true
      t.integer :idx, null: true

      # Exact Frappe field structure from chapter_reference.json
      # This is a child table (istable: 1) with parent references
      t.string :chapter, null: false                   # Link to Course Chapter, reqd: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :chapter_references, :chapter
    add_index :chapter_references, :parent
    add_index :chapter_references, :parenttype
    add_index :chapter_references, :parentfield
    add_index :chapter_references, [ :parent, :parenttype, :parentfield ], name: 'index_chapter_refs_on_parent_and_type_and_field'
    add_index :chapter_references, :creation
    add_index :chapter_references, :modified

    # Add foreign key constraints
    add_foreign_key :chapter_references, :course_chapters, column: :chapter
  end
end
