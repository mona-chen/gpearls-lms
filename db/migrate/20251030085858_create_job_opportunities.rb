class CreateJobOpportunities < ActiveRecord::Migration[7.2]
  def change
    create_table :job_opportunities do |t|
      t.string :job_title, null: false
      t.string :location
      t.string :country
      t.string :type # Full-time/Part-time/Contract
      t.string :work_mode # Remote/On-site/Hybrid
      t.string :company_name
      t.string :company_logo
      t.string :company_website
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.boolean :published, default: true

      t.timestamps
    end
  end
end
