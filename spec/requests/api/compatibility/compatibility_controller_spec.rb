require 'rails_helper'

RSpec.describe 'API::Compatibility', type: :request do
  let(:user) { create(:user) }
  let(:instructor) { create(:user, :instructor) }
  let(:moderator) { create(:user, :moderator) }
  let(:evaluator) { create(:user, :evaluator) }
  let(:course) { create(:course, :published, :with_lessons, instructor: instructor) }
  let(:batch) { create(:batch, :active, instructor: instructor) }

  describe 'POST /api/method/*method_path' do
    context 'with authenticated user' do
      let(:headers) { auth_headers(user) }

      describe 'lms.api.get_user_info' do
        it 'returns user information in Frappe-compatible format' do
          post '/api/method/lms.api.get_user_info', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
          expect(json_response['message']['email']).to eq(user.email)
          expect(json_response['message']['full_name']).to eq(user.full_name || user.email)
          expect(json_response['message']['username']).to eq(user.email.split('@').first)
          expect(json_response['message']['roles']).to include('LMS Student')
          expect(json_response['message']['enabled']).to eq(1)
          expect(json_response['message']['user_type']).to eq('LMS Student')
          expect(json_response['message']['site_info']).to be_present
        end

        it 'includes instructor-specific data for instructor user' do
          post '/api/method/lms.api.get_user_info', headers: auth_headers(instructor)

          json_response = JSON.parse(response.body)
          expect(json_response['message']['roles']).to include('Course Creator')
          expect(json_response['message']['user_type']).to eq('Course Creator')
        end

        it 'includes moderator-specific data for moderator user' do
          post '/api/method/lms.api.get_user_info', headers: auth_headers(moderator)

          json_response = JSON.parse(response.body)
          expect(json_response['message']['roles']).to include('Moderator')
          expect(json_response['message']['user_type']).to eq('Moderator')
        end

        it 'includes evaluator-specific data for evaluator user' do
          post '/api/method/lms.api.get_user_info', headers: auth_headers(evaluator)

          json_response = JSON.parse(response.body)
          expect(json_response['message']['roles']).to include('Batch Evaluator')
          expect(json_response['message']['user_type']).to eq('Batch Evaluator')
        end
      end

      describe 'lms.api.get_all_users' do
        it 'returns list of users with limited fields' do
          create_list(:user, 3)

          post '/api/method/lms.api.get_all_users', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
          expect(json_response['message']['data']).to be_an(Array)
          expect(json_response['message']['data'].length).to be <= 10

          user_data = json_response['message']['data'].first
          expect(user_data).to have_key('name')
          expect(user_data).to have_key('email')
          expect(user_data).to have_key('username')
          expect(user_data).to have_key('first_name')
          expect(user_data).to have_key('last_name')
          expect(user_data).to have_key('user_image')
        end
      end

      describe 'lms.api.get_notifications' do
        let!(:notification) { create(:notification, user: user) }

        it 'returns user notifications' do
          post '/api/method/lms.api.get_notifications', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_an(Array)
        end
      end

      describe 'lms.api.mark_as_read' do
        let!(:notification) { create(:notification, user: user, read: false) }

        it 'marks notification as read' do
          post '/api/method/lms.api.mark_as_read', headers: headers,
               params: { notification_id: notification.id }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to eq({ 'success' => true })
          expect(notification.reload.read).to be true
        end

        context 'with non-existent notification' do
          it 'returns error' do
            post '/api/method/lms.api.mark_as_read', headers: headers,
                 params: { notification_id: 99999 }.to_json

            expect(response).to have_http_status(:success)
            json_response = JSON.parse(response.body)

            expect(json_response['message']).to eq({ 'error' => 'Notification not found' })
          end
        end
      end

      describe 'lms.api.mark_all_as_read' do
        let!(:unread_notifications) { create_list(:notification, 3, user: user, read: false) }

        it 'marks all notifications as read' do
          post '/api/method/lms.api.mark_all_as_read', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to eq({ 'success' => true })

          unread_notifications.each do |notification|
            expect(notification.reload.read).to be true
          end
        end
      end

      describe 'lms.api.get_branding' do
        it 'returns branding information' do
          post '/api/method/lms.api.get_branding', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
        end
      end

      describe 'lms.api.get_lms_setting' do
        it 'returns LMS settings' do
          post '/api/method/lms.api.get_lms_setting', headers: headers,
               params: { field: 'enable_certificates' }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_present
        end
      end

      describe 'lms.api.get_translations' do
        it 'returns translations' do
          post '/api/method/lms.api.get_translations', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
        end
      end

      describe 'lms.api.get_sidebar_settings' do
        it 'returns sidebar settings' do
          post '/api/method/lms.api.get_sidebar_settings', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
        end
      end

      describe 'lms.api.get_certification_categories' do
        it 'returns certification categories' do
          post '/api/method/lms.api.get_certification_categories', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_an(Array)
        end
      end

      describe 'lms.api.get_count_of_certified_members' do
        it 'returns count of certified members' do
          post '/api/method/lms.api.get_count_of_certified_members', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Integer)
        end
      end

      describe 'lms.api.get_certified_participants' do
        it 'returns certified participants' do
          post '/api/method/lms.api.get_certified_participants', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_an(Array)
        end
      end

      describe 'lms.api.get_job_opportunities' do
        let!(:job_opportunity) { create(:job_opportunity) }

        it 'returns job opportunities' do
          post '/api/method/lms.api.get_job_opportunities', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_an(Array)
        end
      end

      describe 'lms.utils.get_my_courses' do
        let!(:enrollment) { create(:enrollment, user: user, course: course) }

        it 'returns user courses with full details' do
          post '/api/method/lms.utils.get_my_courses', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_an(Array)
          expect(json_response['message'].length).to be > 0

          course_data = json_response['message'].first
          expect(course_data['name']).to eq(course.id)
          expect(course_data['title']).to eq(course.title)
          expect(course_data['published']).to eq(course.published)
          expect(course_data['featured']).to eq(course.featured)
          expect(course_data['category']).to eq(course.category)
          expect(course_data['status']).to eq('Approved')
          expect(course_data['lessons']).to eq(course.lessons.count)
          expect(course_data['enrollments']).to eq(course.enrollments.count)
          expect(course_data['membership']).to be_present
        end

        it 'returns featured courses when no enrollments exist' do
          enrollment.destroy
          featured_course = create(:course, :featured, :published)

          post '/api/method/lms.utils.get_my_courses', headers: headers

          json_response = JSON.parse(response.body)
          course_names = json_response['message'].map { |c| c['name'] }
          expect(course_names).to include(featured_course.id)
        end
      end

      describe 'lms.utils.get_courses' do
        it 'returns courses with filtering' do
          post '/api/method/lms.utils.get_courses', headers: headers,
               params: { filters: { published: 1, upcoming: 0 } }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
          expect(json_response['message']['data']).to be_an(Array)

          course_data = json_response['message']['data'].first
          expect(course_data).to have_key('name')
          expect(course_data).to have_key('title')
          expect(course_data).to have_key('description')
          expect(course_data).to have_key('category')
          expect(course_data).to have_key('instructor')
          expect(course_data).to have_key('rating')
          expect(course_data).to have_key('enrollment_count')
        end
      end

      describe 'lms.utils.get_course_completion_data' do
        it 'returns course completion analytics' do
          post '/api/method/lms.utils.get_course_completion_data', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
        end
      end

      describe 'lms.utils.get_tags' do
        before do
          course.update!(tags: 'ruby, rails, testing')
        end

        it 'returns course tags as array' do
          post '/api/method/lms.utils.get_tags', headers: headers,
               params: { course: course.id }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to eq([ 'ruby', ' rails', ' testing' ])
        end
      end

      describe 'lms.utils.get_reviews' do
        it 'returns course reviews' do
          post '/api/method/lms.utils.get_reviews', headers: headers,
               params: { course: course.id }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_an(Array)
        end
      end

      describe 'lms.utils.get_my_batches' do
        let!(:batch_enrollment) { create(:batch_enrollment, user: user, batch: batch) }

        it 'returns user batches with details' do
          post '/api/method/lms.utils.get_my_batches', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_an(Array)
          expect(json_response['message'].length).to be > 0

          batch_data = json_response['message'].first
          expect(batch_data['name']).to eq(batch.id)
          expect(batch_data['title']).to eq(batch.title)
          expect(batch_data['description']).to eq(batch.description)
          expect(batch_data['start_date']).to eq(batch.start_date.strftime('%Y-%m-%d'))
          expect(batch_data['end_date']).to eq(batch.end_date.strftime('%Y-%m-%d'))
          expect(batch_data['enrollment']).to be_present
        end
      end

      describe 'lms.utils.get_batches' do
        it 'returns batches with filtering' do
          post '/api/method/lms.utils.get_batches', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_an(Array)
        end
      end

      describe 'lms.utils.get_upcoming_evals' do
        let!(:certificate_request) do
          create(:certificate_request, user: user, course: course, status: 'Upcoming', date: Date.today + 1.day)
        end

        it 'returns upcoming evaluations' do
          post '/api/method/lms.utils.get_upcoming_evals', headers: headers,
               params: { courses: [ course.id ], batch: nil }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_an(Array)
          expect(json_response['message'].length).to be > 0

          eval_data = json_response['message'].first
          expect(eval_data['name']).to eq(certificate_request.id)
          expect(eval_data['course']).to eq(course.id)
          expect(eval_data['course_title']).to eq(course.title)
          expect(eval_data['member']).to eq(user.email)
        end
      end

      describe 'lms.utils.get_streak_info' do
        it 'returns user streak information' do
          create(:lesson_progress, user: user, created_at: 1.day.ago)

          post '/api/method/lms.utils.get_streak_info', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
          expect(json_response['message']).to have_key('current_streak')
          expect(json_response['message']).to have_key('longest_streak')
          expect(json_response['message']['current_streak']).to be_a(Integer)
          expect(json_response['message']['longest_streak']).to be_a(Integer)
        end
      end

      describe 'lms.utils.get_my_live_classes' do
        let(:live_class) { create(:live_class, batch: batch, date: Date.today + 1.day) }
        let!(:batch_enrollment) { create(:batch_enrollment, user: user, batch: batch) }

        it 'returns upcoming live classes' do
          post '/api/method/lms.utils.get_my_live_classes', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_an(Array)
          expect(json_response['message'].length).to be > 0

          class_data = json_response['message'].first
          expect(class_data['name']).to eq(live_class.id)
          expect(class_data['title']).to eq(live_class.title)
          expect(class_data['description']).to eq(live_class.description)
          expect(class_data['date']).to eq(live_class.date)
          expect(class_data['duration']).to eq(live_class.duration)
          expect(class_data['start_url']).to eq(live_class.start_url)
          expect(class_data['join_url']).to eq(live_class.join_url)
          expect(class_data['owner']).to eq(instructor.email)
        end
      end

      describe 'lms.utils.get_heatmap_data' do
        it 'returns heatmap activity data' do
          create(:lesson_progress, user: user, created_at: 1.day.ago)

          post '/api/method/lms.utils.get_heatmap_data', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
        end
      end

      describe 'lms.utils.get_chart_data' do
        it 'returns chart data' do
          post '/api/method/lms.utils.get_chart_data', headers: headers,
               params: { chart_name: 'course_progress' }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
        end
      end

      describe 'lms.utils.save_current_lesson' do
        let!(:enrollment) { create(:enrollment, user: user, course: course) }
        let(:lesson) { course.lessons.first }

        it 'saves current lesson for user' do
          post '/api/method/lms.utils.save_current_lesson', headers: headers,
               params: { course: course.id, lesson: lesson.id }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
          expect(json_response['message']['success']).to be true

          enrollment.reload
          expect(enrollment.current_lesson).to eq(lesson.id)
        end

        it 'returns error when not enrolled' do
          enrollment.destroy

          post '/api/method/lms.utils.save_current_lesson', headers: headers,
               params: { course: course.id, lesson: lesson.id }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']['success']).to be false
          expect(json_response['message']['error']).to eq('Enrollment not found')
        end
      end

      describe 'lms.api.get_chart_details' do
        it 'returns chart details' do
          post '/api/method/lms.api.get_chart_details', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
        end
      end

      describe 'frappe.apps.get_apps' do
        it 'returns available apps' do
          post '/api/method/frappe.apps.get_apps', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_an(Array)
        end
      end

      describe 'frappe.client.get' do
        it 'gets document by doctype and filters' do
          post '/api/method/frappe.client.get', headers: headers,
               params: { doctype: 'User', filters: { email: user.email } }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Hash)
        end
      end

      describe 'frappe.client.get_single_value' do
        it 'gets single value from document' do
          post '/api/method/frappe.client.get_single_value', headers: headers,
               params: { doctype: 'User', field: 'email', filters: { email: user.email } }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_present
        end
      end

      describe 'frappe.client.get_count' do
        it 'gets count of documents' do
          post '/api/method/frappe.client.get_count', headers: headers,
               params: { doctype: 'User' }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_a(Integer)
        end
      end

      describe 'frappe.desk.search.search_link' do
        it 'searches for linked documents' do
          post '/api/method/frappe.desk.search.search_link', headers: headers,
               params: { doctype: 'User', txt: user.email.split('@').first }.to_json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_an(Array)
        end
      end

      describe 'logout' do
        it 'logs out user' do
          post '/api/method/logout', headers: headers

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['message']).to be_present
        end
      end
    end

    context 'without authentication' do
      describe 'public endpoints' do
        it 'allows access to get_branding' do
          post '/api/method/lms.api.get_branding'

          expect(response).to have_http_status(:success)
        end

        it 'allows access to get_translations' do
          post '/api/method/lms.api.get_translations'

          expect(response).to have_http_status(:success)
        end

        it 'allows access to get_courses' do
          post '/api/method/lms.utils.get_courses'

          expect(response).to have_http_status(:success)
        end

        it 'allows access to get_tags' do
          post '/api/method/lms.utils.get_tags', params: { course: course.id }.to_json

          expect(response).to have_http_status(:success)
        end

        it 'allows access to get_reviews' do
          post '/api/method/lms.utils.get_reviews', params: { course: course.id }.to_json

          expect(response).to have_http_status(:success)
        end
      end

      describe 'protected endpoints' do
        it 'returns unauthorized for get_user_info' do
          post '/api/method/lms.api.get_user_info'

          expect(response).to have_http_status(:unauthorized)
          json_response = JSON.parse(response.body)
          expect(json_response['message']).to eq('Not authenticated')
        end

        it 'returns unauthorized for get_my_courses' do
          post '/api/method/lms.utils.get_my_courses'

          expect(response).to have_http_status(:unauthorized)
          json_response = JSON.parse(response.body)
          expect(json_response['message']).to eq('Not authenticated')
        end

        it 'returns unauthorized for get_my_batches' do
          post '/api/method/lms.utils.get_my_batches'

          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns unauthorized for get_streak_info' do
          post '/api/method/lms.utils.get_streak_info'

          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns unauthorized for save_current_lesson' do
          post '/api/method/lms.utils.save_current_lesson',
               params: { course: course.id, lesson: course.lessons.first.id }.to_json

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context 'with invalid method path' do
      it 'returns 404 for unknown method' do
        post '/api/method/lms.api.unknown_method', headers: auth_headers(user)

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to include('Unknown method')
      end
    end

    context 'with server errors' do
      it 'handles service errors gracefully' do
        allow(Frappe::LmsUtilsService).to receive(:get_my_courses).and_raise(StandardError.new('Database error'))

        post '/api/method/lms.utils.get_my_courses', headers: auth_headers(user)

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to include('Internal server error')
      end
    end

    context 'parameter handling' do
      it 'handles JSON parameters correctly' do
        post '/api/method/lms.utils.get_tags',
             headers: { 'Content-Type' => 'application/json' }.merge(auth_headers(user)),
             params: { course: course.id }.to_json

        expect(response).to have_http_status(:success)
      end

      it 'handles form parameters correctly' do
        post '/api/method/lms.utils.get_tags', headers: auth_headers(user),
             params: { course: course.id }

        expect(response).to have_http_status(:success)
      end

      it 'handles missing parameters gracefully' do
        post '/api/method/lms.utils.get_tags', headers: auth_headers(user)

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq([])
      end
    end
  end
end
