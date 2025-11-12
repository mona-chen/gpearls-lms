module System
  class ClientService
    def self.get(doctype: nil, filters: {}, name: nil)
      case doctype
      when 'User'
        get_user(name, filters)
      when 'LMS Course'
        get_course(name)
      when 'LMS Batch'
        get_batch(name)
      else
        Rails.logger.warn "Unsupported doctype for frappe.client.get: #{doctype}"
        nil
      end
    end

    def self.get_list(doctype:, filters: {})
      case doctype
      when 'Course'
        get_course_list(filters)
      when 'User'
        get_user_list(filters)
      when 'Batch'
        get_batch_list(filters)
      else
        []
      end
    end

    def self.get_single_value(doctype:, field:, filters: {})
      case doctype
      when 'LMS Settings'
        get_lms_setting_value(field)
      else
        nil
      end
    end

    def self.get_count(doctype:)
      case doctype
      when 'User'
        User.count
      when 'LMS Course'
        Course.count
      when 'LMS Batch'
        Batch.count
      when 'LMS Certificate'
        Certificate.count
      when 'Job Opportunity'
        JobOpportunity.count
      else
        Rails.logger.warn "Unsupported doctype for frappe.client.get_count: #{doctype}"
        0
      end
    end

    def self.logout
      # This should be handled by the controller directly for session/cookie clearing
      { 'message' => 'Logged out successfully', 'status' => 'success' }
    end

    private

    def self.get_user(name, filters)
      user = nil

      if name
        # Handle both integer IDs and string representations
        if name.to_i.to_s == name.to_s
          user = User.find_by(id: name.to_i)
        else
          user = User.find_by(email: name) || User.find_by(first_name: name) || User.find_by(last_name: name)
        end
      elsif filters['username']
        user = User.find_by(email: filters['username']) || User.find_by(username: filters['username'])
      elsif filters['email']
        user = User.find_by(email: filters['email'])
      end

      if user
        {
          name: user.id.to_s,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          full_name: user.full_name,
          username: user.email&.split('@')&.first,
          user_image: user.user_image,
          enabled: user.enabled,
          user_type: user.user_type,
          creation: user.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          modified: user.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        }
      else
        nil
      end
    end

    def self.get_course(name)
      course = Course.find_by(id: name) || Course.find_by(title: name)
      if course
        {
          name: course.id,
          title: course.title,
          description: course.description,
          short_introduction: course.short_introduction,
          category: course.category,
          tags: course.tags,
          status: course.published ? 'Published' : 'Draft',
          creation: course.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          modified: course.updated_at.strftime('%Y-%m-%d %H:%M:%S'),
          owner: course.instructor&.email
        }
      else
        nil
      end
    end

    def self.get_batch(name)
      batch = Batch.find_by(id: name) || Batch.find_by(name: name)
      if batch
        {
          name: batch.id,
          batch_name: batch.name,
          description: batch.description,
          start_date: batch.start_date&.strftime('%Y-%m-%d'),
          end_date: batch.end_date&.strftime('%Y-%m-%d'),
          status: batch.published ? 'Published' : 'Draft',
          creation: batch.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          modified: batch.updated_at.strftime('%Y-%m-%d %H:%M:%S'),
          owner: batch.instructor&.email
        }
      else
        nil
      end
    end

    def self.get_lms_setting_value(field)
      # Mock settings values for common LMS settings
      case field
      when 'allow_guest_access'
        true
      when 'prevent_skipping_videos'
        false
      when 'contact_us_email'
        'info@lms.com'
      when 'contact_us_url'
        '/contact'
      when 'livecode_url'
        'https://livecode.lms.com'
      when 'default_language'
        'en'
      else
        nil
      end
    end

    def self.get_course_list(filters)
      courses = Course.all

      if filters['published']
        courses = courses.where(published: true)
      end

      courses.limit(20).map do |course|
        {
          name: course.id,
          title: course.title,
          category: course.category,
          published: course.published,
          creation: course.created_at.strftime('%Y-%m-%d %H:%M:%S')
        }
      end
    end

    def self.get_user_list(filters)
      users = User.all

      if filters['enabled']
        users = users.where(enabled: filters['enabled'])
      end

      users.limit(20).map do |user|
        {
          name: user.id,
          email: user.email,
          full_name: user.full_name,
          enabled: user.enabled,
          user_type: user.user_type
        }
      end
    end

    def self.get_batch_list(filters)
      batches = Batch.all

      if filters['published']
        batches = batches.where(published: true)
      end

      batches.limit(20).map do |batch|
        {
          name: batch.id,
          title: batch.title,
          start_date: batch.start_date&.strftime('%Y-%m-%d'),
          published: batch.published
        }
      end
    end
  end
end
