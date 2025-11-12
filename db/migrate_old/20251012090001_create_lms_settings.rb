# This migration is deprecated - lms_settings table is created in 20251012090000_create_critical_lms_doctypes.rb
# Keeping this file for historical reference but it should be deleted in production

class CreateLmsSettings < ActiveRecord::Migration[7.0]
  def change
    # No-op - table already created in 20251012090000_create_critical_lms_doctypes.rb
  end
end
