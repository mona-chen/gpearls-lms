class CreatePwaInstallTracking < ActiveRecord::Migration[7.0]
  def change
    create_table :pwa_install_trackings do |t|
      t.references :user, null: true, foreign_key: true
      t.string :action, null: false # prompted, accepted, dismissed
      t.string :platform, null: false # ios, android, windows, macos, etc.
      t.text :user_agent
      t.datetime :timestamp, null: false
      t.string :ip_address
      t.json :metadata

      t.timestamps
    end

    add_index :pwa_install_trackings, [ :action ]
    add_index :pwa_install_trackings, [ :platform ]
    add_index :pwa_install_trackings, [ :timestamp ]
    add_index :pwa_install_trackings, [ :user_id, :timestamp ]
  end
end
