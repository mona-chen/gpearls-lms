class CreateZoomSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :zoom_settings do |t|
      # Zoom Settings specific fields (based on Frappe Zoom Settings doctype)
      t.string :account_name, null: false                # Zoom account name
      t.string :api_key, null: false                     # Zoom API key
      t.string :api_secret, null: false                  # Zoom API secret (encrypted)
      t.string :webhook_secret, null: true               # Webhook verification secret
      t.string :account_id, null: false                  # Zoom account ID
      t.string :user_id, null: false                     # Default user ID for meetings
      t.string :user_email, null: false                  # Default user email
      t.boolean :enabled, default: true                  # Whether Zoom integration is enabled
      t.boolean :auto_record_meetings, default: false    # Auto-record meetings
      t.string :recording_option, default: "local"       # Recording option (local, cloud, none)
      t.boolean :enable_chat, default: true              # Enable meeting chat
      t.boolean :enable_waiting_room, default: true      # Enable waiting room
      t.boolean :enable_breakout_rooms, default: true    # Enable breakout rooms
      t.boolean :enable_polling, default: true           # Enable polling
      t.boolean :enable_annotation, default: true        # Enable annotation
      t.boolean :enable_remote_control, default: true    # Enable remote control
      t.boolean :enable_co_host, default: true           # Enable co-host feature
      t.boolean :mute_on_entry, default: false           # Mute participants on entry
      t.string :default_meeting_duration, default: "60"  # Default meeting duration in minutes
      t.string :default_timezone, default: "UTC"         # Default timezone for meetings
      t.text :meeting_settings                           # Additional meeting settings (JSON)
      t.text :security_settings                          # Security settings (JSON)
      t.string :alternative_hosts, null: true            # Alternative hosts (comma-separated)
      t.boolean :require_password, default: false        # Require password for meetings
      t.string :password_type, default: "numeric"        # Password type (numeric, alphanumeric)
      t.integer :password_length, default: 6             # Password length
      t.boolean :enable_join_before_host, default: false # Allow join before host
      t.integer :join_before_host_minutes, default: 5    # Minutes before host can join
      t.boolean :auto_start_recording, default: false    # Auto-start recording
      t.boolean :auto_stop_recording, default: false     # Auto-stop recording
      t.text :recording_settings                        # Recording-specific settings (JSON)
      t.boolean :enable_live_transcription, default: false # Enable live transcription
      t.string :transcription_language, default: "en-US" # Transcription language
      t.boolean :save_captions, default: false           # Save captions
      t.text :branding_settings                          # Branding customization (JSON)
      t.string :meeting_theme, null: true                # Custom meeting theme
      t.boolean :virtual_background_enabled, default: true # Enable virtual backgrounds
      t.text :virtual_background_settings                # Virtual background settings (JSON)
      t.datetime :last_sync_at, null: true               # Last synchronization with Zoom
      t.string :sync_status, default: "success"          # Sync status (success, error, pending)
      t.text :sync_error_message                         # Sync error details
      t.integer :api_call_count, default: 0              # API call usage counter
      t.datetime :api_rate_limit_reset_at, null: true    # API rate limit reset time
      t.boolean :webhook_enabled, default: false         # Whether webhooks are enabled
      t.string :webhook_url, null: true                  # Webhook endpoint URL
      t.text :webhook_events                             # Enabled webhook events (JSON)
      t.datetime :last_webhook_received_at, null: true   # Last webhook received timestamp
      t.boolean :test_mode, default: false               # Test mode for development
      t.text :test_meeting_settings                      # Test meeting configuration (JSON)
      t.references :created_by, foreign_key: { to_table: :users }, null: true  # Who created settings
      t.references :updated_by, foreign_key: { to_table: :users }, null: true  # Who last updated settings

      t.timestamps
    end

    # Add indexes for performance and common queries
    add_index :zoom_settings, :account_name, unique: true
    add_index :zoom_settings, :api_key
    add_index :zoom_settings, :account_id
    # user_id index automatically created by references helper
    add_index :zoom_settings, :enabled
    add_index :zoom_settings, :auto_record_meetings
    add_index :zoom_settings, :recording_option
    add_index :zoom_settings, :default_timezone
    add_index :zoom_settings, :last_sync_at
    add_index :zoom_settings, :sync_status
    add_index :zoom_settings, :webhook_enabled
    add_index :zoom_settings, :test_mode
    # created_by_id and updated_by_id indexes automatically created by references helpers
    add_index :zoom_settings, [:enabled, :sync_status]
    add_index :zoom_settings, [:account_name, :enabled]
  end
end
