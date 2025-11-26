namespace :lms do
  desc "Install LMS - sets up roles, permissions, and initial data"
  task install: :environment do
    puts "🚀 LMS Installation Started..."

    Lms::InstallService.after_install
    Lms::InstallService.after_sync

    puts "✅ LMS Installation Completed!"
  end

  desc "Sync LMS - updates permissions and data after migrations"
  task sync: :environment do
    puts "🔄 LMS Sync Started..."

    Lms::InstallService.after_sync

    puts "✅ LMS Sync Completed!"
  end

  desc "Setup LMS - runs both install and sync"
  task setup: [ :install, :sync ] do
    puts "🎉 LMS Setup Completed!"
    puts ""
    puts "Next steps:"
    puts "1. Configure your web server (nginx/apache)"
    puts "2. Set up SSL certificates"
    puts "3. Configure email settings"
    puts "4. Set up background job processing (Sidekiq)"
    puts "5. Configure file storage (AWS S3, etc.)"
    puts "6. Review and customize LMS settings"
  end

  desc "Check LMS installation status"
  task status: :environment do
    puts "🔍 LMS Installation Status"
    puts "=" * 30

    checks = {
      "Database" => ActiveRecord::Base.connection.active?,
      "Admin User" => User.where(is_admin: true).exists?,
      "LMS Roles" => Role.count > 0,
      "LMS Settings" => LmsSetting.count > 0,
      "Setup Completed" => LmsSetting.get_value("setup_completed", false),
      "Sample Course" => Course.exists?,
      "Email Templates" => NotificationTemplate.count > 0
    }

    checks.each do |check, status|
      icon = status ? "✅" : "❌"
      puts "#{icon} #{check}: #{status}"
    end

    puts ""
    if checks.values.all?
      puts "🎉 LMS is fully installed and ready!"
    else
      puts "⚠️  LMS installation is incomplete. Run 'rails lms:setup' to complete."
    end
  end

  desc "Reset LMS installation (WARNING: This will delete all data)"
  task reset: :environment do
    if ENV["CONFIRM_RESET"] != "yes"
      puts "❌ DANGER: This will delete ALL LMS data!"
      puts "To proceed, run: CONFIRM_RESET=yes rails lms:reset"
      exit 1
    end

    puts "🗑️  Resetting LMS installation..."

    # Clear all LMS data
    Notification.delete_all
    CertificateRequest.delete_all
    Certificate.delete_all
    QuizSubmission.delete_all
    AssignmentSubmission.delete_all
    Enrollment.delete_all
    CourseLesson.delete_all
    CourseChapter.delete_all
    Course.delete_all
    BatchEnrollment.delete_all
    Batch.delete_all
    LmsSetting.delete_all
    Role.delete_all
    User.delete_all

    puts "✅ LMS data cleared. Run 'rails lms:setup' to reinstall."
  end
end
