namespace :lms do
  desc "Install LMS system with default data and configurations"
  task install: :environment do
    puts "🚀 Installing LMS system..."
    
    # Run migrations first
    Rake::Task['db:migrate'].invoke
    
    # Create LMS roles
    create_lms_roles
    
    # Create default categories and sources
    create_default_categories
    create_batch_sources
    
    # Set default configurations
    set_default_configurations
    
    # Create email templates
    create_email_templates
    
    # Give admin roles
    give_lms_roles_to_admin
    
    # Create default notification settings
    create_notification_settings
    
    puts "✅ LMS installation completed successfully!"
    puts "👤 Admin user has been granted all LMS roles"
    puts "📧 Email templates have been created"
    puts "⚙️  Default configurations have been set"
  end
  
  desc "Uninstall LMS system"
  task uninstall: :environment do
    puts "🗑️  Uninstalling LMS system..."
    
    delete_custom_fields
    delete_lms_roles
    delete_email_templates
    
    puts "✅ LMS uninstallation completed"
  end
  
  desc "Create LMS roles"
  task create_roles: :environment do
    create_lms_roles
    puts "✅ LMS roles created"
  end
  
  desc "Setup email templates"
  task setup_email_templates: :environment do
    create_email_templates
    puts "✅ Email templates created"
  end
  
  private
  
  def create_lms_roles
    puts "📋 Creating LMS roles..."
    
    roles = [
      {
        name: "Course Creator",
        description: "Can create and manage courses",
        permissions: %w[course:create course:edit course:delete lesson:create lesson:edit]
      },
      {
        name: "Moderator", 
        description: "Can moderate discussions and content",
        permissions: %w[discussion:moderate comment:moderate user:moderate]
      },
      {
        name: "Batch Evaluator",
        description: "Can evaluate student submissions and assignments",
        permissions: %w[assignment:grade quiz:grade certificate:issue evaluation:conduct]
      },
      {
        name: "LMS Student",
        description: "Standard student role with course access",
        permissions: %w[course:enroll lesson:view quiz:take assignment:submit]
      },
      {
        name: "LMS Admin",
        description: "Full administrative access to LMS",
        permissions: %w[admin:all]
      }
    ]
    
    roles.each do |role_data|
      role = Role.find_or_create_by(name: role_data[:name]) do |r|
        r.description = role_data[:description]
        r.permissions = role_data[:permissions]
        r.system_role = true
      end
      
      puts "  ✓ Created role: #{role.name}"
    end
  end
  
  def delete_lms_roles
    role_names = ["Course Creator", "Moderator", "Batch Evaluator", "LMS Student", "LMS Admin"]
    
    role_names.each do |role_name|
      role = Role.find_by(name: role_name)
      if role&.system_role
        # Remove from users first
        HasRole.where(role: role).destroy_all
        role.destroy
        puts "  ✓ Deleted role: #{role_name}"
      end
    end
  end
  
  def create_default_categories
    puts "📚 Creating default categories..."
    
    categories = [
      { title: "Programming", description: "Programming and software development courses" },
      { title: "Data Science", description: "Data science and analytics courses" },
      { title: "Design", description: "UI/UX and graphic design courses" },
      { title: "Business", description: "Business and entrepreneurship courses" },
      { title: "Marketing", description: "Digital marketing and growth courses" },
      { title: "Language", description: "Language learning courses" }
    ]
    
    categories.each do |category_data|
      category = LmsCategory.find_or_create_by(title: category_data[:title]) do |c|
        c.description = category_data[:description]
        c.published = true
      end
      
      puts "  ✓ Created category: #{category.title}"
    end
  end
  
  def create_batch_sources
    puts "📊 Creating batch sources..."
    
    sources = [
      "Newsletter",
      "LinkedIn", 
      "Twitter",
      "Website",
      "Friend/Colleague/Connection",
      "Google Search",
      "Facebook",
      "Instagram",
      "YouTube",
      "Referral Program"
    ]
    
    sources.each do |source_name|
      if defined?(LmsSource)
        source = LmsSource.find_or_create_by(source: source_name)
        puts "  ✓ Created source: #{source.source}"
      end
    end
  end
  
  def set_default_configurations
    puts "⚙️  Setting default configurations..."
    
    # Create or update LMS settings
    if defined?(LmsSetting)
      settings = LmsSetting.first_or_create
      
      settings.update!(
        app_name: "Learning Management System",
        app_description: "A comprehensive learning platform",
        allow_self_enrollment: true,
        auto_create_course_batches: false,
        enable_discussions: true,
        enable_certificates: true,
        enable_payments: true,
        default_currency: "USD",
        daily_digest_enabled: true,
        notification_enabled: true
      )
      
      puts "  ✓ LMS settings configured"
    end
  end
  
  def create_email_templates
    puts "📧 Creating email templates..."
    
    templates = [
      {
        name: "Batch Confirmation",
        subject: "Batch Enrollment Confirmation - {{course_title}}",
        template_type: "batch_enrollment",
        description: "Sent when a student enrolls in a batch"
      },
      {
        name: "Mentor Request Creation",
        subject: "Request for Mentorship",
        template_type: "mentor_request",
        description: "Sent when someone applies to become a mentor"
      },
      {
        name: "Certificate Notification", 
        subject: "Certificate Evaluation Scheduled - {{course_title}}",
        template_type: "certificate",
        description: "Sent when certificate evaluation is scheduled"
      },
      {
        name: "Assignment Submission",
        subject: "New Assignment Submission - {{assignment_title}}",
        template_type: "assignment",
        description: "Sent to instructors when students submit assignments"
      },
      {
        name: "Live Class Reminder",
        subject: "Live Class Reminder - {{class_title}}",
        template_type: "live_class",
        description: "Sent before live classes start"
      },
      {
        name: "Daily Digest",
        subject: "Your Daily Learning Digest - {{date}}",
        template_type: "notification",
        description: "Daily summary of activities and updates"
      }
    ]
    
    templates.each do |template_data|
      if defined?(EmailTemplate)
        template = EmailTemplate.find_or_create_by(name: template_data[:name]) do |t|
          t.subject = template_data[:subject]
          t.template_type = template_data[:template_type]
          t.description = template_data[:description]
          t.active = true
        end
        
        puts "  ✓ Created email template: #{template.name}"
      end
    end
  end
  
  def delete_email_templates
    if defined?(EmailTemplate)
      EmailTemplate.where(system_template: true).destroy_all
    end
  end
  
  def give_lms_roles_to_admin
    puts "👤 Assigning LMS roles to admin users..."
    
    admin_users = User.where(email: ['admin@example.com', 'administrator@localhost'])
                      .or(User.where(roles: { admin: true }))
                      .or(User.where("email ILIKE ?", "%admin%"))
    
    lms_roles = Role.where(name: ["Course Creator", "Moderator", "Batch Evaluator", "LMS Admin"])
    
    admin_users.each do |admin|
      lms_roles.each do |role|
        unless admin.has_role?(role.name)
          HasRole.create!(user: admin, role: role)
          puts "  ✓ Assigned #{role.name} to #{admin.email}"
        end
      end
    end
  end
  
  def create_notification_settings
    puts "🔔 Creating notification settings..."
    
    notification_types = [
      { name: "course_enrollment", description: "Course enrollment notifications", default_enabled: true },
      { name: "assignment_due", description: "Assignment due reminders", default_enabled: true },
      { name: "live_class_reminder", description: "Live class reminders", default_enabled: true },
      { name: "certificate_issued", description: "Certificate issued notifications", default_enabled: true },
      { name: "daily_digest", description: "Daily activity digest", default_enabled: false },
      { name: "discussion_mention", description: "Discussion mentions", default_enabled: true },
      { name: "course_updates", description: "Course content updates", default_enabled: true }
    ]
    
    notification_types.each do |notification_data|
      if defined?(NotificationType)
        NotificationType.find_or_create_by(name: notification_data[:name]) do |nt|
          nt.description = notification_data[:description]
          nt.default_enabled = notification_data[:default_enabled]
        end
        
        puts "  ✓ Created notification type: #{notification_data[:name]}"
      end
    end
  end
  
  def delete_custom_fields
    # Clean up any custom fields if they exist in the system
    puts "🧹 Cleaning up custom fields..."
    
    custom_fields = [
      "user_category", "headline", "college", "city", "verify_terms",
      "country", "preferred_location", "preferred_functions", "preferred_industries",
      "skill", "certification", "github", "linkedin", "medium", "profession"
    ]
    
    if defined?(CustomField)
      CustomField.where(fieldname: custom_fields).destroy_all
      puts "  ✓ Removed custom fields"
    end
  end
end