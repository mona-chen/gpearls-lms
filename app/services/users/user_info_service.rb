module Users
  class UserInfoService
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      {
        name: @user.id, # Frappe uses 'name' as the primary key
        email: @user.email,
        enabled: @user.enabled ? 1 : 0,
        user_image: @user.user_image || "",
        full_name: @user.full_name,
        user_type: @user.user_type || "LMS Student",
        username: @user.username,
        roles: user_roles,
        is_instructor: @user.instructor?,
        is_moderator: @user.moderator?,
        is_evaluator: @user.evaluator?,
        is_student: @user.student?,
        is_fc_site: false, # Not applicable in Rails context
        is_system_manager: @user.user_type == "Administrator",
        sitename: "Frappe LMS",
        developer_mode: false, # Not applicable in Rails context
        course_progress: calculate_overall_course_progress,
        last_active: Time.current.strftime("%Y-%m-%d %H:%M:%S"),
        site_info: site_info,
        mobile_no: @user.phone || "",
        desk_settings: {},
        route_permissions: [],
        defaults: {}
      }
    end

    private

    def calculate_overall_course_progress
      return 0 if @user.enrollments.empty?

      total_lessons = 0
      completed_lessons = 0

      @user.enrollments.each do |enrollment|
        course = enrollment.course
        next unless course

        course_lessons = course.lessons.count
        lesson_ids = course.lessons.pluck(:id)
        completed_lessons += LessonProgress.where(user: @user, lesson_id: lesson_ids, completed: true)
                                      .count
        total_lessons += course_lessons
      end

      total_lessons > 0 ? (completed_lessons.to_f / total_lessons * 100).round(2) : 0
    end

    def map_user_type_to_frappe(user_type)
      case user_type
      when "Course Creator"
        "Course Creator"
      when "Moderator"
        "Moderator"
      when "Batch Evaluator"
        "Batch Evaluator"
      when "Administrator"
        "System Manager"
      else
        "LMS Student"
      end
    end

    def user_roles
      roles = [ "LMS Student" ]

      case @user.user_type
      when "Course Creator"
        roles += [ "Course Creator", "Workspace Manager", "Lesson Creator" ]
      when "Moderator"
        roles += [ "Moderator", "LMS Manager", "Course Reviewer" ]
      when "Batch Evaluator"
        roles += [ "Batch Evaluator", "Quiz Reviewer" ]
      when "Administrator"
        roles += [ "System Manager", "Administrator", "LMS Manager" ]
      end

      unless @user.user_type == "LMS Student" || @user.user_type.nil?
        roles += [ "Course Creator", "Batch Manager" ]
      end

      roles.uniq
    end

    def site_info
      {
        name: "Frappe LMS",
        country: "India",
        timezone: "Asia/Kolkata"
      }
    end
  end
end
