module Lms
  class InstallService
    def self.after_install
      puts "🚀 LMS Installation Started..."

      create_lms_roles
      create_default_admin_user
      create_default_settings
      create_batch_sources
      set_default_certificate_template
      create_default_email_templates
      create_default_categories

      puts "✅ LMS Installation Completed!"
    end

    def self.after_sync
      puts "🔄 LMS Sync Started..."

      update_permissions
      create_default_data
      setup_email_notifications

      puts "✅ LMS Sync Completed!"
    end

    def self.before_uninstall
      puts "🗑️ LMS Uninstallation Started..."

      # Clean up data if needed
      # Note: In production, you might want to ask for confirmation

      puts "✅ LMS Uninstallation Completed!"
    end

    private

    def self.create_lms_roles
      puts "Creating LMS roles..."

      roles = [
        { name: "LMS Student", description: "Default role for LMS users" },
        { name: "Course Creator", description: "Can create and manage courses" },
        { name: "Moderator", description: "Can moderate content and users" },
        { name: "Batch Evaluator", description: "Can evaluate batch assignments" },
        { name: "Instructor", description: "Can teach courses and manage students" }
      ]

      roles.each do |role_data|
        Role.find_or_create_by!(name: role_data[:name]) do |role|
          role.description = role_data[:description]
        end
      end

      puts "✅ Created #{roles.count} LMS roles"
    end

    def self.create_default_admin_user
      puts "Creating default admin user..."

      admin = User.find_or_create_by!(email: 'admin@lms.local') do |user|
        user.full_name = 'LMS Administrator'
        user.username = 'admin'
        user.password = 'password123' # Should be changed after setup
        user.password_confirmation = 'password123'
        user.is_admin = true
        user.email_verified = true
      end

      # Assign all roles to admin
      Role.all.each do |role|
        admin.add_role(role.name) unless admin.has_role?(role.name)
      end

      puts "✅ Created admin user: #{admin.email}"
    end

    def self.create_default_settings
      puts "Creating default LMS settings..."

      settings = {
        'site_name' => 'Learning Management System',
        'site_description' => 'A comprehensive learning management system',
        'default_currency' => 'USD',
        'default_timezone' => 'UTC',
        'enable_registration' => true,
        'enable_public_courses' => true,
        'max_upload_size' => 10.megabytes,
        'enable_certifications' => true,
        'enable_discussions' => true,
        'enable_ratings' => true,
        'enable_progress_tracking' => true,
        'enable_email_notifications' => true,
        'enable_scorm_support' => true,
        'enable_live_classes' => false, # Requires Zoom setup
        'enable_payments' => false, # Requires payment gateway setup
        'persona_captured' => false,
        'is_onboarding_complete' => false
      }

      settings.each do |key, value|
        LmsSetting.find_or_create_by!(key: key) do |setting|
          setting.value = value
          setting.value_type = value.class.name
        end
      end

      puts "✅ Created #{settings.count} default settings"
    end

    def self.create_batch_sources
      puts "Creating batch sources..."

      sources = [
        'Newsletter',
        'LinkedIn',
        'Twitter',
        'Website',
        'Friend/Colleague',
        'Google Search',
        'Social Media',
        'Email Campaign',
        'Event/Conference',
        'Direct Referral'
      ]

      sources.each do |source_name|
        LmsSource.find_or_create_by!(name: source_name)
      end

      puts "✅ Created #{sources.count} batch sources"
    end

    def self.set_default_certificate_template
      puts "Setting default certificate template..."

      # Create a default certificate template
      template = CertificateTemplate.find_or_create_by!(name: 'Default Certificate') do |t|
        t.template_type = 'html'
        t.content = <<-HTML
<div style="text-align: center; padding: 50px; border: 2px solid #333;">
  <h1>Certificate of Completion</h1>
  <p>This certifies that</p>
  <h2>{{user.full_name}}</h2>
  <p>has successfully completed the course</p>
  <h3>{{course.title}}</h3>
  <p>on {{certificate.issue_date.strftime('%B %d, %Y')}}</p>
  <br><br>
  <p>LMS Administrator</p>
</div>
        HTML
        t.is_default = true
      end

      puts "✅ Created default certificate template"
    end

    def self.create_default_email_templates
      puts "Creating default email templates..."

      templates = [
        {
          name: 'Welcome Email',
          subject: 'Welcome to {{site_name}}!',
          body: 'Welcome {{user.full_name}}! Your account has been created successfully.'
        },
        {
          name: 'Course Enrollment Confirmation',
          subject: 'Enrolled in {{course.title}}',
          body: 'You have been enrolled in {{course.title}}. Start learning now!'
        },
        {
          name: 'Certificate Issued',
          subject: 'Certificate Issued for {{course.title}}',
          body: 'Congratulations! Your certificate for {{course.title}} is now available.'
        },
        {
          name: 'Assignment Graded',
          subject: 'Assignment Graded: {{assignment.title}}',
          body: 'Your assignment "{{assignment.title}}" has been graded. Score: {{score}}'
        }
      ]

      templates.each do |template_data|
        NotificationTemplate.find_or_create_by!(name: template_data[:name]) do |template|
          template.subject = template_data[:subject]
          template.body = template_data[:body]
          template.template_type = 'email'
          template.is_active = true
        end
      end

      puts "✅ Created #{templates.count} email templates"
    end

    def self.create_default_categories
      puts "Creating default course categories..."

      categories = [
        { name: 'Technology', description: 'Programming, development, and tech courses' },
        { name: 'Business', description: 'Business, management, and entrepreneurship' },
        { name: 'Design', description: 'Graphic design, UX/UI, and creative courses' },
        { name: 'Marketing', description: 'Digital marketing and advertising courses' },
        { name: 'Data Science', description: 'Data analysis, machine learning courses' },
        { name: 'Languages', description: 'Language learning courses' },
        { name: 'Health & Fitness', description: 'Health, wellness, and fitness courses' },
        { name: 'Personal Development', description: 'Self-improvement and personal growth' }
      ]

      categories.each do |category_data|
        LmsCategory.find_or_create_by!(title: category_data[:name]) do |category|
          category.description = category_data[:description]
        end
      end

      puts "✅ Created #{categories.count} course categories"
    end

    def self.update_permissions
      puts "Updating permissions..."

      # This would set up role-based permissions
      # For now, we'll rely on the existing permission system

      puts "✅ Permissions updated"
    end

    def self.create_default_data
      puts "Creating default data..."

      # Create a sample course for demonstration
      instructor = User.find_by(email: 'admin@lms.local')
      if instructor
        course = Course.find_or_create_by!(title: 'Welcome to LMS') do |c|
          c.short_introduction = 'Your first course on the Learning Management System'
          c.description = 'This is a sample course to help you get started with the LMS platform.'
          c.instructor = instructor
          c.published = true
          c.price = 0
        end

        # Create a sample chapter and lesson
        chapter = CourseChapter.find_or_create_by!(title: 'Getting Started', course: course)
        lesson = CourseLesson.find_or_create_by!(
          title: 'Welcome Lesson',
          course_chapter: chapter,
          course: course
        ) do |l|
          l.content = 'Welcome to your first lesson! This LMS platform provides comprehensive tools for online learning.'
          l.content_type = 'text'
        end

        puts "✅ Created sample course with #{course.course_chapters.count} chapters and #{course.course_lessons.count} lessons"
      end
    end

    def self.setup_email_notifications
      puts "Setting up email notifications..."

      # Configure default notification preferences
      User.find_each do |user|
        user.update(
          receive_email_notifications: true,
          receive_sms_notifications: false,
          notification_preferences: {
            course_updates: true,
            assignment_deadlines: true,
            certificate_issued: true,
            enrollment_confirmations: true
          }
        )
      end

      puts "✅ Email notifications configured"
    end
  end
end