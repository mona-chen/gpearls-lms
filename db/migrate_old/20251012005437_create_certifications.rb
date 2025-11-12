class CreateCertifications < ActiveRecord::Migration[7.2]
  def change
    create_table :certifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :evaluator, null: false, foreign_key: true
      t.string :status
      t.string :certificate_number
      t.datetime :issued_at

      t.timestamps
    end
  end
end
