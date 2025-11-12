class CreateEducationDetails < ActiveRecord::Migration[7.2]
  def change
    create_table :education_details do |t|
      # This is a child table (istable: 1 in Frappe), so it needs parent reference
      # In Frappe, child tables are associated with their parent through parent field

      # Reference to parent user (this will be filled by the parent)
      t.string :parent, null: false, index: true
      t.string :parenttype, null: false, default: "User"
      t.integer :parentfield, null: false, default: 0

      # Core fields
      t.string :institution_name, null: false, index: true
      t.string :location, null: false, index: true
      t.string :degree_type, null: false, index: true
      t.string :major, null: false, index: true
      t.string :grade_type # Percentage, Point of Score, Letter Grade, UK Grading, French, CGPA/4
      t.string :grade
      t.date :start_date
      t.date :end_date

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
