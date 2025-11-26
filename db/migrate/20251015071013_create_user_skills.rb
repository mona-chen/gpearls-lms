class CreateUserSkills < ActiveRecord::Migration[7.2]
  def change
    create_table :user_skills do |t|
      # User Skills specific fields (based on Frappe User Skill doctype)
      t.references :user, null: false, foreign_key: true  # User reference
      t.string :skill_name, null: false                   # Name of the skill
      t.string :proficiency_level, default: "Beginner"    # Proficiency level (Beginner, Intermediate, Advanced, Expert)
      t.integer :years_of_experience, default: 0          # Years of experience
      t.string :last_used                                 # When skill was last used
      t.text :description                                # Additional description
      t.boolean :verified, default: false                 # Whether skill is verified
      t.string :verified_by                               # Who verified the skill
      t.datetime :verified_on                             # Verification date
      t.text :certifications                             # Related certifications (JSON)
      t.string :skill_level                              # Alternative skill level field
      t.integer :sort_order, default: 0                  # Sort order for display

      t.timestamps
    end

    # Add indexes for performance
    add_index :user_skills, :skill_name
    add_index :user_skills, :proficiency_level
    add_index :user_skills, :verified
    add_index :user_skills, :years_of_experience
    add_index :user_skills, [ :user_id, :skill_name ], unique: true
  end
end
