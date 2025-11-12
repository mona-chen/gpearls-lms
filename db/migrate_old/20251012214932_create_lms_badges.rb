class CreateLmsBadges < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_badges do |t|
      t.string :name
      t.string :title
      t.text :description
      t.string :badge_type
      t.string :category
      t.string :difficulty_level
      t.integer :points
      t.integer :level
      t.string :tier
      t.string :color
      t.string :icon
      t.string :image
      t.references :owner, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :batch, null: false, foreign_key: true
      t.string :status
      t.integer :issuance_limit
      t.integer :expires_after_days
      t.boolean :is_hidden
      t.boolean :is_system_generated

      t.timestamps
    end
  end
end
