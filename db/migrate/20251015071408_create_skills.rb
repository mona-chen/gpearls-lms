class CreateSkills < ActiveRecord::Migration[7.2]
  def change
    create_table :skills do |t|
      # Skills specific fields (based on Frappe Skill doctype)
      t.string :name, null: false                    # Skill name (primary field)
      t.string :description                          # Skill description
      t.string :category, null: true                 # Skill category (Technical, Soft Skills, etc.)
      t.string :skill_type, default: "Technical"     # Type of skill
      t.integer :proficiency_levels, default: 4      # Number of proficiency levels
      t.string :default_level, default: "Beginner"   # Default proficiency level
      t.boolean :is_active, default: true            # Whether skill is active
      t.string :icon, null: true                     # Icon for skill
      t.string :color, null: true                    # Color code for skill
      t.text :competency_criteria                    # Criteria for each level (JSON)
      t.integer :sort_order, default: 0              # Sort order for display
      t.string :parent_skill, null: true             # Parent skill for hierarchy
      t.integer :usage_count, default: 0             # How many times this skill is used
      t.text :custom_fields                          # Custom fields (JSON)

      t.timestamps
    end

    # Add indexes for performance
    add_index :skills, :name, unique: true
    add_index :skills, :category
    add_index :skills, :skill_type
    add_index :skills, :is_active
    add_index :skills, :parent_skill
    add_index :skills, :usage_count
    add_index :skills, :sort_order
  end
end
