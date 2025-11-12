class CreateCertificateRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :certificate_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :evaluator, null: false, foreign_key: true
      t.date :date
      t.datetime :start_time
      t.datetime :end_time
      t.string :status
      t.string :google_meet_link
      t.decimal :rating
      t.text :summary

      t.timestamps
    end
  end
end
