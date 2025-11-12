class CreateWorkExperiences < ActiveRecord::Migration[7.2]
  def change
    create_table :work_experiences do |t|
      # This is a child table (istable: 1 in Frappe), so it needs parent reference
      # In Frappe, child tables are associated with their parent through parent field

      # Reference to parent user (this will be filled by the parent)
      t.string :parent, null: false, index: true
      t.string :parenttype, null: false, default: "User"
      t.integer :parentfield, null: false, default: 0

      # Core fields
      t.string :title, null: false, index: true
      t.string :company, null: false, index: true
      t.string :location, null: false, index: true
      t.text :description # Small Text
      t.boolean :current, default: false, index: true
      t.date :from_date, null: false, index: true
      t.date :to_date # Mandatory unless current

      # Frappe standard fields for child tables
      t.string :name, null: false, index: { unique: true }
      t.string :owner
      t.datetime :creation
      t.datetime :modified

      # Rails timestamps
      t.timestamps
    end

    # Indexes already added by t.index in create_table - no need to add separately
  end
end
