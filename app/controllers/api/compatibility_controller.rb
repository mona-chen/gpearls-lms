class Api::CompatibilityController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  include Current
  before_action :authenticate_user_from_token!

  # Frappe-style API compatibility layer - Direct method routing like @frappe.whitelist()

  def handle_method
    method_path = params[:method_path]
    Rails.logger.info "Received method path: #{method_path}"

    # Set current user for services
    Current.user = authenticate_user_from_token!

    # Route to appropriate Frappe service method
    begin
      result = route_to_frappe_method(method_path)

      if result.is_a?(Hash) && result[:error]
        render json: { message: result[:error] }, status: result[:status]
      elsif result != nil || method_path.start_with?("frappe.client.")
        # For frappe.client methods, nil means "not found" which is valid
        render json: { message: result }
      else
        render json: {
          "message" => "Unknown method: #{method_path}",
          "status" => "error"
        }, status: 404
      end
    rescue => e
      Rails.logger.error "Error in Frappe method #{method_path}: #{e.message}"
      render json: {
        "message" => "Internal server error: #{e.message}",
        "status" => "error"
      }, status: 500
    end
  end

  private

  def route_to_frappe_method(method_path)
    # Convert ActionController::Parameters to regular hash for services
    safe_params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h

    # Ensure all nested parameters are also converted
    safe_params = deep_convert_params(safe_params)

    case method_path
    # LMS API methods
    when "lms.api.get_user_info"
      if Current.user
        Users::UserInfoService.call(Current.user)
      else
        { error: "Not authenticated", status: :unauthorized }
      end
    when "lms.api.capture_user_persona"
      if Current.user
        # Parse the responses JSON and capture persona
        responses = JSON.parse(safe_params[:responses] || "{}") rescue {}
        Current.user.update!(
          persona_role: responses["role"],
          persona_use_case: responses["use_case"],
          persona_responses: safe_params[:responses],
          persona_captured_at: Time.current
        )
        { success: true, message: "Persona captured successfully" }
      else
        { error: "Not authenticated", status: :unauthorized }
      end
    when "lms.api.get_all_users"
      Users::UsersService.call
    when "lms.api.get_notifications"
      if Current.user
        Notifications::UserNotificationsService.call(Current.user)
      else
        { error: "Not authenticated", status: :unauthorized }
      end
    when "lms.api.mark_as_read"
      if Current.user
        Notifications::MarkAsReadService.call(params[:notification_id], Current.user)
      else
        { error: "Not authenticated", status: :unauthorized }
      end
    when "lms.api.mark_all_as_read"
      if Current.user
        Notifications::MarkAllAsReadService.call(Current.user)
      else
        { error: "Not authenticated", status: :unauthorized }
      end
    when "lms.utils.upload_assignment"
      if Current.user
        AssignmentService.upload(safe_params, Current.user)
      else
        { error: "Not authenticated", status: :unauthorized }
      end
    when "lms.api.get_file_info"
      FileInfoService.call(safe_params[:file_url])
    when "lms.api.get_branding"
      Settings::BrandingService.call
    when "lms.api.get_lms_setting"
      Settings::LmsSettingsService.call(field: safe_params[:field])
    when "lms.api.get_translations"
      Settings::TranslationsService.call
    when "lms.api.get_sidebar_settings"
      Settings::SidebarSettingsService.call
    when "lms.api.get_certification_categories"
      Certifications::CategoriesService.call(params)
    when "lms.api.get_count_of_certified_members"
      Certifications::CountService.call
    when "lms.api.get_certified_participants"
      Certifications::ParticipantsService.call(params)
    when "lms.api.get_job_opportunities"
       Jobs::OpportunitiesService.call(params)
    when "lms.utils.cancel_request"
       if Current.user
         Jobs::ApplicationsService.cancel_request(Current.user, safe_params[:job_opportunity_id])
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.create_request"
       if Current.user
         Jobs::ApplicationsService.create_request(Current.user, safe_params[:job_opportunity_id], safe_params)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.has_requested"
       if Current.user
         result = Jobs::ApplicationsService.has_requested(Current.user, safe_params[:job_opportunity_id])
         { has_requested: result }
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.capture_interest"
       if Current.user
         Jobs::ApplicationsService.capture_interest(Current.user, safe_params[:job_opportunity_id], safe_params)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.capture_user_persona"
       if Current.user
         Jobs::ApplicationsService.capture_user_persona(Current.user, safe_params)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.get_schedule"
       if Current.user
         System::UtilitiesService.get_schedule(Current.user, safe_params)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.report"
       if Current.user
         System::UtilitiesService.report(Current.user, safe_params[:report_type], safe_params)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.send_confirmation_email"
       if Current.user
         System::UtilitiesService.send_confirmation_email(Current.user, safe_params[:email_type], safe_params)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.setup_calendar_event"
       if Current.user
         System::UtilitiesService.setup_calendar_event(Current.user, safe_params)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.update_current_membership"
       if Current.user
         System::UtilitiesService.update_current_membership(Current.user, safe_params)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.create_membership"
       if Current.user
         System::UtilitiesService.create_membership(Current.user, safe_params)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.create_certificate_request"
       if Current.user
         System::UtilitiesService.create_certificate_request(Current.user, safe_params)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.create_lms_certificate_evaluation"
       if Current.user
         System::UtilitiesService.create_lms_certificate_evaluation(Current.user, safe_params)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.get_posthog_settings"
       System::UtilitiesService.get_posthog_settings
    when "lms.utils.reindex_exercises"
       if Current.user
         Courses::CoursesService.reindex_exercises(safe_params[:course], Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.get_lesson_creation_details"
       if Current.user
         Courses::CoursesService.get_lesson_creation_details(safe_params[:course], Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.autosave_section"
       if Current.user
         Courses::CoursesService.autosave_section(safe_params[:course], safe_params[:chapter], safe_params[:lesson], safe_params[:content], Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.update_chapter_index"
       if Current.user
         Courses::CoursesService.update_chapter_index(safe_params[:course], safe_params[:chapter], safe_params[:index], Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.update_lesson_index"
       if Current.user
         Courses::CoursesService.update_lesson_index(safe_params[:course], safe_params[:chapter], safe_params[:lesson], safe_params[:index], Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.upsert_chapter"
       if Current.user
         Courses::CoursesService.upsert_chapter(safe_params[:course], safe_params, Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.api.get_announcements"
       Notifications::AnnouncementsService.call(safe_params)
    when "lms.lms.user.sign_up"
      # Handle user signup
      email = safe_params.dig("args", "email") || safe_params["email"]
      full_name = safe_params.dig("args", "full_name") || safe_params["full_name"]
      verify_terms = safe_params.dig("args", "verify_terms") || safe_params["verify_terms"]
      user_category = safe_params.dig("args", "user_category") || safe_params["user_category"]

      if email.blank? || full_name.blank?
        { message: "Email and full name are required" }
      else
        # Check if user already exists
        existing_user = User.find_by(email: email)
        if existing_user
          { message: "Already Registered" }
        else
          # Create new user
          user = User.create!(
            email: email,
            full_name: full_name,
            first_name: full_name.split(" ").first,
            last_name: full_name.split(" ").drop(1).join(" "),
            password: SecureRandom.hex(8), # Generate random password
            role: "LMS Student" # Default role
          )
          { success: true }
        end
      end

    # Onboarding methods
    when "lms.utils.is_onboarding_complete"
      if Current.user
        Onboarding::OnboardingService.call(user: Current.user)
      else
        { error: "Not authenticated", status: :unauthorized }
      end
    when "lms.onboarding.get_first_course"
      if Current.user
        { first_course: Onboarding::OnboardingService.new(Current.user).get_first_course }
      else
        { error: "Not authenticated", status: :unauthorized }
      end
    when "lms.onboarding.get_first_batch"
      if Current.user
        { first_batch: Onboarding::OnboardingService.new(Current.user).get_first_batch }
      else
        { error: "Not authenticated", status: :unauthorized }
      end
    when "lms.onboarding.is_onboarding_complete"
      if Current.user
        Onboarding::OnboardingService.call(user: Current.user)
      else
        { error: "Not authenticated", status: :unauthorized }
      end
    when "frappe.client.set_value"
      if safe_params[:doctype] == "LMS Settings" && safe_params[:fieldname] == "is_onboarding_complete"
        LmsSetting.set_onboarding_complete(safe_params[:value] == 1)
        { success: true }
      elsif safe_params[:doctype] == "User"
        # Handle User field updates
        user = User.find_by(id: safe_params[:name])
        if user
          # Handle different field formats
          fieldname = safe_params[:fieldname]
          value = safe_params[:value]

          # If fieldname is a hash (multiple fields), handle each field
          if fieldname.is_a?(Hash)
            fieldname.each do |field, val|
              case field
              when "first_name"
                user.update!(first_name: val)
              when "last_name"
                user.update!(last_name: val)
              when "headline"
                user.update!(headline: val)
              when "bio"
                user.update!(bio: val)
              when "description"
                user.update!(description: val)
              when "github"
                user.update!(github: val)
              when "linkedin"
                user.update!(linkedin: val)
              when "website"
                user.update!(website: val)
              when "company"
                user.update!(company: val)
              when "phone"
                user.update!(phone: val)
              when "location"
                user.update!(location: val)
              when "user_image"
                user.update!(user_image: val)
              when "enabled"
                user.update!(enabled: val == 1 || val == true)
              when "enabled"
                user.update!(enabled: val == 1 || val == true)
              else
                # For other fields, try to update if they exist
                if user.respond_to?(field.to_s + "=")
                  begin
                    user.update!(field => val)
                  rescue ActiveRecord::UnknownAttributeError
                    # Skip unknown fields silently
                  end
                end
              end
            end
          else
            # Handle single field
            case fieldname
            when "first_name"
              user.update!(first_name: value)
            when "last_name"
              user.update!(last_name: value)
            when "headline"
              user.update!(headline: value)
            when "bio"
              user.update!(bio: value)
            when "description"
              user.update!(description: value)
            when "github"
              user.update!(github: value)
            when "linkedin"
              user.update!(linkedin: value)
            when "website"
              user.update!(website: value)
            when "company"
              user.update!(company: value)
            when "phone"
              user.update!(phone: value)
            when "location"
              user.update!(location: value)
            when "user_image"
              user.update!(user_image: value)
            when "enabled"
              user.update!(enabled: value == 1 || value == true)
            else
              # For other fields, try to update if they exist
              if user.respond_to?(fieldname.to_s + "=")
                begin
                  user.update!(fieldname => value)
                rescue ActiveRecord::UnknownAttributeError
                  # Skip unknown fields silently
                end
              end
            end
          end
          { success: true }
        else
          { error: "User not found", status: :not_found }
        end
      else
        { error: "Invalid parameters", status: :unprocessable_entity }
      end

    # LMS Utils methods - Exact Frappe function replicas
    when "lms.utils.get_my_courses"
       Courses::MyCoursesService.call(current_user)
    when "lms.utils.get_created_courses"
       if Current.user
         Courses::CoursesService.get_created_courses(Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.get_courses"
      Courses::CoursesService.call(safe_params)
    when "lms.utils.get_course_details"
      Courses::CourseDetailsService.call(safe_params[:course], current_user)
    when "lms.utils.get_course_completion_data"
      Analytics::CourseAnalyticsService.get_completion_data
    when "lms.utils.get_course_progress_distribution"
      Analytics::CourseAnalyticsService.get_progress_distribution(safe_params[:course])
    when "lms.utils.get_tags"
      Frappe::LmsUtilsService.get_tags(safe_params[:course])
    when "lms.utils.get_reviews"
      course = Course.find_by(id: safe_params[:course])
      Courses::CourseReviewService.get_reviews(course)
    when "lms.utils.save_current_lesson"
       Frappe::LmsUtilsService.save_current_lesson(safe_params[:course], safe_params[:lesson])
    when "lms.utils.get_lesson_info"
       Lessons::LessonService.get_info(safe_params[:lesson])
    when "lms.utils.mark_lesson_progress"
       Lessons::ProgressService.mark(safe_params[:course], safe_params[:chapter], safe_params[:lesson], Current.user)
    when "lms.utils.track_video_watch_duration"
       Lessons::VideoService.track_duration(safe_params, Current.user)
    when "lms.utils.get_my_batches"
       Batches::MyBatchesService.call(Current.user)
    when "lms.utils.get_created_batches"
       if Current.user
         Batches::BatchesService.get_created_batches(Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.get_batches"
      Batches::BatchesService.call(params)
    when "lms.utils.get_batch_students"
      Batches::BatchStudentsService.call(safe_params[:batch_name], safe_params[:status])
    when "lms.utils.get_batch_timetable"
      Batches::BatchTimetableService.call(safe_params[:batch_name], start_date: safe_params[:start_date], end_date: safe_params[:end_date])
    when "lms.utils.enroll_in_batch"
       Batches::BatchEnrollmentService.enroll_in_batch(safe_params[:batch_name], Current.user)
    when "lms.utils.get_batch_details"
       Batches::BatchDetailsService.call(safe_params[:batch_name], Current.user)
    when "lms.utils.get_batch_courses"
       Batches::BatchCoursesService.call(safe_params[:batch_name])
    when "lms.utils.create_certificate"
       Certifications::CertificateService.create_certificate(safe_params, Current.user)
    when "lms.utils.save_certificate_details"
       Certifications::CertificateService.save_certificate_details(safe_params, Current.user)
    when "lms.utils.create_lms_certificate"
       Certifications::CertificateService.create_lms_certificate(safe_params, Current.user)
    when "lms.api.get_certification_categories"
      Certifications::CertificationCategoriesService.call
    when "lms.api.get_certified_participants"
       Certifications::CertifiedParticipantsService.call(params)
    when "lms.api.get_members"
       # Get members with search functionality
       search = safe_params[:search] || ""
       if search.present?
         # Use SQLite-compatible case-insensitive search
         users = User.where(status: "Active")
                     .where("lower(full_name) LIKE lower(?) OR lower(username) LIKE lower(?) OR lower(email) LIKE lower(?)",
                           "%#{search}%", "%#{search}%", "%#{search}%")
                     .limit(50)
       else
         users = User.where(status: "Active").limit(50)
       end

       users_data = users.map do |user|
         {
           name: user.id,
           username: user.username,
           full_name: user.full_name,
           user_image: user.user_image
         }
       end
       users_data
    when "lms.api.get_unsplash_photos"
       # Get stock photos from Unsplash for course images
       query = safe_params[:query] || "education"
       page = safe_params[:page] || 1
       per_page = safe_params[:per_page] || 20

       # Mock implementation - in production this would call Unsplash API
       photos = (1..per_page.to_i).map do |i|
         {
           id: "photo_#{page}_#{i}",
           urls: {
             small: "https://source.unsplash.com/random/400x300/?#{query},#{i}",
             regular: "https://source.unsplash.com/random/800x600/?#{query},#{i}",
             full: "https://source.unsplash.com/random/1200x800/?#{query},#{i}"
           },
           alt_description: "#{query} photo #{i}",
           user: {
             name: "Unsplash User #{i}",
             links: {
               html: "https://unsplash.com/@user#{i}"
             }
           }
         }
       end

       { photos: photos, total_pages: 10, current_page: page }
    when "lms.api.get_assigned_badges"
       if Current.user
         # Get badges assigned to the current user
         badges = Current.user.badges || []
         badge_details = badges.map do |badge_name|
           {
             name: badge_name,
             title: badge_name.titleize,
             description: "Achievement badge for #{badge_name}",
             icon: "/badges/#{badge_name}.png",
             earned_at: Current.user.created_at.strftime("%Y-%m-%d"),
             category: "achievement"
           }
         end
         { badges: badge_details }
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.api.get_admin_evals"
       Certifications::AdminEvalsService.call(params)
    when "lms.utils.cancel_evaluation"
       if Current.user
         Certifications::CertificateService.cancel_evaluation(safe_params, Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.save_evaluation_details"
       if Current.user
         Certifications::CertificateService.save_evaluation_details(safe_params, Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
      Certifications::AdminEvalsService.call(params)
    when "lms.utils.get_programs"
      Programs::ProgramsService.call(params)
    when "lms.utils.get_program_details"
      Programs::ProgramDetailsService.call(safe_params[:program_name], Current.user)
    when "lms.utils.enroll_in_program"
       Programs::ProgramEnrollmentService.enroll_in_program(safe_params[:program_name], Current.user)
    when "lms.utils.get_programs"
       Programs::ProgramsService.call
    when "lms.utils.get_program_details"
       Programs::ProgramDetailsService.call(safe_params[:program_name], Current.user)
    when "lms.utils.get_discussion_topics"
       Discussions::DiscussionTopicsService.call(params)
    when "lms.utils.get_discussion_replies"
       Discussions::DiscussionRepliesService.call(safe_params[:discussion], params)
    when "lms.utils.save_message"
        Discussions::SaveMessageService.call(safe_params, Current.user)
    when "lms.utils.submit_review"
        Discussions::SubmitReviewService.call(safe_params, Current.user)
    when "lms.utils.get_order_summary"
      Payments::OrderSummaryService.call(safe_params[:order_id], Current.user)
    when "lms.utils.get_payment_link"
      Payments::PaymentLinkService.call(safe_params, Current.user)
    when "lms.utils.validate_billing_access"
      Payments::BillingAccessService.call(safe_params, Current.user)
    when "lms.api.get_payment_gateway_details"
      Payments::PaymentGatewayService.call
    when "lms.utils.get_upcoming_evals"
       Frappe::LmsUtilsService.get_upcoming_evals(params[:courses], params[:batch])
    when "lms.utils.get_assessments"
       AssessmentsService.call(safe_params, Current.user)
    when "lms.utils.get_question_details"
        QuizService::QuestionService.get_details(safe_params[:question])
    when "lms.utils.check_answer"
         QuizService::AnswerService.check(safe_params[:question], safe_params[:answer])
    when "lms.utils.submit_solution"
        QuizService::SubmissionService.submit(safe_params[:exercise], safe_params[:code], Current.user)
    when "lms.utils.quiz_summary"
       Quiz::SummaryService.get_summary(safe_params[:quiz], Current.user)
    when "lms.utils.create_programming_exercise_submission"
        Quiz::ProgrammingSubmissionService.create(safe_params, Current.user)
    when "lms.utils.get_assignment"
       AssignmentService.get_details(safe_params[:assignment])
    when "lms.utils.save_assignment"
       if Current.user
         AssignmentService.save(safe_params, Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.grade_assignment"
       if Current.user
         AssignmentService.grade(safe_params[:assignment], safe_params[:score], Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.get_streak_info"
      Analytics::StreakInfoService.call(Current.user)
    when "lms.utils.get_my_live_classes"
       Frappe::LmsUtilsService.get_my_live_classes
    when "lms.utils.get_admin_live_classes"
       if Current.user
         Frappe::LmsUtilsService.get_admin_live_classes
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.get_heatmap_data"
       Analytics::HeatmapDataService.call(Current.user)
    when "lms.utils.join_cohort"
       if Current.user
         cohort = Cohort.find_by(id: safe_params[:cohort])
         subgroup = CohortSubgroup.find_by(id: safe_params[:subgroup])
         Cohorts::CohortService.join_cohort(Current.user, cohort, subgroup, safe_params[:invite_code])
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.approve_cohort_join_request"
       if Current.user
         join_request = CohortJoinRequest.find_by(id: safe_params[:request_id])
         Cohorts::CohortService.approve_join_request(join_request, Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.reject_cohort_join_request"
       if Current.user
         join_request = CohortJoinRequest.find_by(id: safe_params[:request_id])
         Cohorts::CohortService.reject_join_request(join_request, safe_params[:reason], Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.undo_reject_cohort_join_request"
       if Current.user
         join_request = CohortJoinRequest.find_by(id: safe_params[:request_id])
         Cohorts::CohortService.undo_reject_join_request(join_request, Current.user)
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.get_roles"
       Users::AdvancedService.get_roles
    when "lms.utils.add_an_evaluator"
       if Current.user
         Users::AdvancedService.add_evaluator(safe_params[:user_email], safe_params[:role] || "Batch Evaluator")
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.delete_evaluator"
       if Current.user
         Users::AdvancedService.delete_evaluator(safe_params[:user_email], safe_params[:role] || "Batch Evaluator")
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.save_role"
       if Current.user
         Users::AdvancedService.save_role(safe_params[:user_email], safe_params[:role])
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.assign_badge"
       if Current.user
         Users::AdvancedService.assign_badge(safe_params[:user_email], safe_params[:badge])
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.get_meta_info"
       if Current.user
         Users::AdvancedService.get_meta_info(safe_params[:user_email])
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.update_meta_info"
       if Current.user
         Users::AdvancedService.update_meta_info(safe_params[:user_email], safe_params[:meta_data] || safe_params.except(:method_path))
       else
         { error: "Not authenticated", status: :unauthorized }
       end
    when "lms.utils.get_chart_data"
      Analytics::ChartService.call(params[:chart_name])

    # Analytics methods
    when "lms.api.get_chart_details"
      Analytics::ChartService.call
    when "lms.api.get_chart_data"
      Analytics::ChartService.call(params[:chart_name])

    # Frappe client methods
    when "frappe.apps.get_apps"
      System::AppsService.call
    when "frappe.client.get"
      System::ClientService.get(doctype: safe_params[:doctype], filters: safe_params[:filters], name: safe_params[:name])
    when "frappe.client.get_list"
      System::ClientService.get_list(doctype: safe_params[:doctype], filters: safe_params[:filters])
    when "frappe.client.get_single_value"
      System::ClientService.get_single_value(doctype: safe_params[:doctype], field: safe_params[:field], filters: safe_params[:filters])
    when "frappe.client.get_count"
      System::ClientService.get_count(doctype: safe_params[:doctype])
    when "frappe.desk.search.search_link"
      Search::LinksService.call(safe_params)

    # System methods
    when "logout"
      logout_user
      System::ClientService.logout
    when "upload_file"
      # Handle file upload for Frappe compatibility
      file_upload_service = System::FileUploadService.call(request, Current.user)
      render json: file_upload_service
    end
  end






  def logout_user
    # Clear all session data
    reset_session

    # Clear all Frappe-style cookies
    cookies.delete(:sid, domain: :all, path: "/")
    cookies.delete(:system_user, domain: :all, path: "/")
    cookies.delete(:full_name, domain: :all, path: "/")
    cookies.delete(:user_id, domain: :all, path: "/")
    cookies.delete(:user_image, domain: :all, path: "/")

    # Also clear Rails session cookie
    cookies.delete(:_session_id, domain: :all, path: "/")

    System::ClientService.logout
  end

  def get_user_info
    unless current_user
      render json: { error: "Not authenticated" }, status: :unauthorized
      return
    end

    render json: Users::UserInfoService.call(current_user)
  end



  def get_lms_setting
    if params[:field]
      Settings::LmsSettingsService.call(field: params[:field])
    else
      Settings::LmsSettingsService.call
    end
  end

  def get_translations
    render json: {
      messages: common_translations
    }
  end


  def get_notifications
    notifications = Notifications::UserNotificationsService.call(current_user)
    render json: { data: notifications }
  end

  def get_my_live_classes
    render json: {
      "data" => {
        message: "Live classes feature coming soon",
        data: []
      }
    }
  end

  def get_streak_info
    streak_data = Analytics::StreakInfoService.call(current_user)
    render json: { data: streak_data }
  end

  private

  def calculate_current_streak(dates)
    return 0 if dates.empty?

    streak = 0
    current_date = Date.today

    dates.each do |date|
      if date == current_date
        streak += 1
        current_date -= 1
      elsif date == current_date - 1
        streak += 1
        current_date -= 1
      else
        break
      end
    end

    streak
  end

  def calculate_longest_streak(dates)
    return 0 if dates.empty?

    longest_streak = 0
    current_streak = 0
    previous_date = nil

    dates.sort.each do |date|
      if previous_date && (date == previous_date + 1 || date == previous_date)
        current_streak += 1
      else
        current_streak = 1
      end

      longest_streak = [ longest_streak, current_streak ].max
      previous_date = date
    end

    longest_streak
  end

  def get_my_courses
    return render json: { data: [] } unless current_user

    courses = Courses::MyCoursesService.call(current_user)
    render json: { data: courses }
  end

  private

  def calculate_course_progress(user, course)
    total_lessons = course.lessons.count
    return 0 if total_lessons == 0

    completed_lessons = LessonProgress.joins(:lesson)
      .where(user: user, lessons: { course: course.id.to_s }, completed: true)
      .count

    ((completed_lessons.to_f / total_lessons) * 100).round(2)
  end

  def get_my_batches
    return render json: { "data" => [] } unless current_user

    batch_enrollments = current_user.batch_enrollments.includes(:batch, :course)

    batches_data = batch_enrollments.map do |enrollment|
      batch = enrollment.batch
      course = batch.course

      {
        name: batch.name,
        title: course&.title || batch.name,
        batch_id: batch.id,
        course_id: course&.id,
        start_date: batch.start_date&.strftime("%Y-%m-%d"),
        end_date: batch.end_date&.strftime("%Y-%m-%d"),
        status: batch_status(enrollment),
        joined_at: enrollment.created_at.strftime("%Y-%m-%d"),
        instructor: batch.instructor&.full_name,
        description: batch.description,
        max_students: batch.max_students,
        current_students: batch.batch_enrollments.count
      }
    end

    render json: { "data" => batches_data }
  end

  private

  def batch_status(enrollment)
    batch = enrollment.batch
    return "Completed" if enrollment.completed?
    return "Not Started" if batch.start_date > Date.today
    return "Active" if batch.end_date >= Date.today
    "Ended"
  end

  def get_upcoming_evals
    return render json: { "data" => [] } unless current_user

    # Get quizzes for user's courses (mock implementation for now)
    user_courses = current_user.enrollments.pluck(:course_id)
    quizzes = Quiz.where(course_id: user_courses)
      .order(:created_at)
      .limit(10)

    evals_data = quizzes.map do |quiz|
      {
        course: quiz.course.title,
        course_id: quiz.course.id,
        quiz: quiz.title,
        quiz_id: quiz.id,
        scheduled_date: quiz.scheduled_date || Date.today.strftime("%Y-%m-%d"),
        duration: quiz.duration || 30,
        max_attempts: quiz.max_attempts || 3,
        passing_percentage: quiz.passing_percentage || 70,
        questions_count: quiz.quiz_questions&.count || 0
      }
    end

    render json: { "data" => evals_data }
  end

  # New API method implementations
  def get_batches
    batches = Batch.includes(:instructor, :course)

    # Apply filters from request
    if params[:filters].present?
      filters = params[:filters].to_unsafe_h
      if filters["start_date"]
        start_date = filters["start_date"].first == ">=" ? Date.today : filters["start_date"].first
        batches = batches.where("start_date >= ?", start_date)
      end
      batches = batches.where(published: true) if filters["published"] == 1
    end

    # Apply ordering
    if params[:order_by].present?
      batches = batches.order(params[:order_by])
    else
      batches = batches.order(start_date: :desc)
    end

    # Apply pagination
    limit = params[:limit] || 20
    offset = params[:start] || 0
    batches = batches.limit(limit).offset(offset)

    batches_data = batches.map do |batch|
      {
        name: batch.name,
        title: batch.name,
        batch_id: batch.id,
        course_id: batch.course&.id,
        course_title: batch.course&.title,
        start_date: batch.start_date&.strftime("%Y-%m-%d"),
        end_date: batch.end_date&.strftime("%Y-%m-%d"),
        instructor: batch.instructor&.full_name,
        description: batch.description,
        max_students: batch.max_students,
        current_students: batch.batch_enrollments.count,
        published: batch.published,
        creation: batch.created_at.strftime("%Y-%m-%d %H:%M:%S"),
        modified: batch.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
        owner: batch.instructor&.email
      }
    end

    render json: { "data" => batches_data }
  end










  def get_count
    doctype = params[:doctype]

    count = case doctype
    when "LMS Course"
              Course.count
    when "LMS Batch"
              Batch.count
    when "LMS Certificate"
              Certificate.count
    when "Job Opportunity"
              JobOpportunity.count
    else
              0
    end

    render json: {
      "data" => {
        "count" => count
      }
    }
  end

  def get_heatmap_data
    heatmap_data = Analytics::HeatmapDataService.call(current_user)
    render json: { data: heatmap_data }
  end

  def save_current_lesson
    return { error: "Not authenticated" } unless current_user

    course_name = params[:course]
    lesson_name = params[:lesson]

    return { error: "Missing parameters" } unless course_name && lesson_name

    enrollment = Enrollment.find_by(user: current_user, course_id: course_name)
    return { error: "Enrollment not found" } unless enrollment

    enrollment.update(current_lesson: lesson_name)
    { "data" => { success: true } }
  end

  def get_tags
    course = params[:course]
    return render json: { "data" => [] } unless course

    course_record = Course.find_by(id: course)
    return render json: { "data" => [] } unless course_record

    tags = course_record.tags&.split(",") || []
    render json: { "data" => tags }
  end

  def get_reviews
    course = params[:course]
    return render json: { data: [] } unless course

    reviews = Reviews::CourseReviewsService.call(course)
    render json: { data: reviews }
  end

  def get_course_progress_distribution
    course = params[:course]
    return render json: { "data" => [] } unless course

    course_record = Course.find_by(id: course)
    return render json: { "data" => [] } unless course_record

    enrollments = course_record.enrollments.pluck(:progress)

    distribution = [
      { category: "0-20%", count: enrollments.count { |p| p >= 0 && p < 20 } },
      { category: "20-40%", count: enrollments.count { |p| p >= 20 && p < 40 } },
      { category: "40-60%", count: enrollments.count { |p| p >= 40 && p < 60 } },
      { category: "60-80%", count: enrollments.count { |p| p >= 60 && p < 80 } },
      { category: "80-100%", count: enrollments.count { |p| p >= 80 && p <= 100 } }
    ]

    average_progress = enrollments.empty? ? 0 : (enrollments.sum.to_f / enrollments.size).round(2)

    render json: {
      "data" => {
        "average_progress" => average_progress,
        "progress_distribution" => distribution
      }
    }
  end

  # Helper methods
  def common_translations
    {
      "Login" => "Login",
      "Logout" => "Logout",
      "Courses" => "Courses",
      "Batches" => "Batches",
      "Students" => "Students",
      "Instructors" => "Instructors",
      "Administrators" => "Administrators",
      "Settings" => "Settings",
      "Profile" => "Profile",
      "Dashboard" => "Dashboard",
      "Analytics" => "Analytics",
      "Reports" => "Reports",
      "Certificates" => "Certificates",
      "Badges" => "Badges",
      "Jobs" => "Jobs",
      "Notifications" => "Notifications",
      "Messages" => "Messages",
      "Help" => "Help",
      "Support" => "Support",
      "About" => "About",
      "Contact" => "Contact",
      "Privacy" => "Privacy",
      "Terms" => "Terms",
      "FAQ" => "FAQ",
      "Documentation" => "Documentation",
      "Community" => "Community"
    }
  end

  def authenticate_user!
    authenticate_user_from_token!
  end

  private

  def authenticate_user_from_token!
    # First try JWT token authentication
    token = request.headers["Authorization"]&.split(" ")&.last
    Rails.logger.info "Authenticating with token: #{token&.first(20)}..."

    if token.present?
      begin
        decoded = JWT.decode(token, ENV.fetch("DEVISE_JWT_SECRET_KEY", Rails.application.secret_key_base), true, { algorithm: "HS256" })
        payload = decoded[0]
        Rails.logger.info "Decoded payload: #{payload}"
        user = User.find_by(id: payload["sub"])
        Rails.logger.info "Found user: #{user&.email}"

        if user && payload["exp"] > Time.now.to_i
          @current_user = user
          Current.user = user  # Set Current.user for compatibility
          Rails.logger.info "JWT authentication successful for #{user.email}"
          return user
        else
          Rails.logger.info "JWT authentication failed - user not found or token expired"
        end
      rescue JWT::DecodeError, JWT::ExpiredSignature => e
        Rails.logger.info "JWT decode error: #{e.message}"
        # If JWT fails, try session authentication
      end
    end

    # Fallback to session-based authentication (Frappe style)
    Rails.logger.info "Trying session-based authentication"
    if session[:user_id].present?
      @current_user = User.find_by(id: session[:user_id])
      if @current_user.present?
        Current.user = @current_user  # Set Current.user for compatibility
        Rails.logger.info "Session authentication successful for #{@current_user.email}"
        return @current_user
      end
    end

    # Check Frappe-style session cookies as last resort
    if cookies[:user_id].present?
      email = CGI.unescape(cookies[:user_id])
      @current_user = User.find_by(email: email)
      if @current_user.present?
        Current.user = @current_user  # Set Current.user for compatibility
        Rails.logger.info "Cookie authentication successful for #{@current_user.email}"
        return @current_user
      end
    end

    Rails.logger.info "All authentication methods failed"
    @current_user = nil
    Current.user = nil
  end

  def current_user
    @current_user
  end

  private

  def deep_convert_params(obj)
    case obj
    when Hash
      obj.transform_values { |value| deep_convert_params(value) }
    when ActionController::Parameters
      deep_convert_params(obj.to_unsafe_h)
    when Array
      obj.map { |item| deep_convert_params(item) }
    else
      obj
    end
  rescue => e
    Rails.logger.error "Error converting parameters: #{e.message}"
    {}
  end
end
