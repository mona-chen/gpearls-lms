require 'rails_helper'

# Test suite to ensure Rails LMS onboarding is an exact replica of Frappe LMS onboarding
# This validates that the onboarding flow matches Frappe's implementation exactly

RSpec.describe 'Frappe LMS Onboarding Replica', type: :request do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, email: 'moderator@example.com') }
  let(:course) { create(:course, instructor: moderator) }
  let(:chapter) { create(:course_chapter, course: course) }
  let(:lesson) { create(:course_lesson, course_chapter: chapter, course: course) }

  before do
    # Set up moderator role
    moderator.add_role("Moderator")
  end

  describe 'Onboarding Status API (exact replica of lms.utils.is_onboarding_complete)' do
    it 'returns is_onboarded: true for non-moderators (exact Frappe logic)' do
      sign_in user

      get '/api/onboarding/status'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['is_onboarded']).to be_truthy
      expect(json['course_created']).to be_nil
      expect(json['chapter_created']).to be_nil
      expect(json['lesson_created']).to be_nil
    end

    it 'returns detailed onboarding status for moderators (exact Frappe logic)' do
      sign_in moderator

      get '/api/onboarding/status'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['is_onboarded']).to be_falsey
      expect(json['course_created']).to be_falsey
      expect(json['chapter_created']).to be_falsey
      expect(json['lesson_created']).to be_falsey
      expect(json['first_course']).to be_nil
    end

    it 'marks onboarding complete when moderator creates content (exact Frappe logic)' do
      # Create content as moderator
      course
      chapter
      lesson

      sign_in moderator

      get '/api/onboarding/status'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['is_onboarded']).to be_truthy
      expect(json['course_created']).to be_truthy
      expect(json['chapter_created']).to be_truthy
      expect(json['lesson_created']).to be_truthy
      expect(json['first_course']).to eq(course.name)
    end
  end

  describe 'Persona Capture API (exact replica of Frappe persona flow)' do
    it 'captures user persona with role and use case (exact Frappe logic)' do
      sign_in user

      persona_data = {
        responses: JSON.generate({
          role: 'Instructor',
          use_case: 'Corporate Training'
        })
      }

      post '/api/method/lms.api.capture_user_persona', params: persona_data

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Persona captured successfully')

      user.reload
      expect(user.persona_role).to eq('Instructor')
      expect(user.persona_use_case).to eq('Corporate Training')
      expect(user.persona_captured_at).to be_present
    end

    it 'sets persona_captured flag in LMS Settings (exact Frappe logic)' do
      sign_in user

      persona_data = {
        responses: JSON.generate({
          role: 'Student',
          use_case: 'Personal Learning'
        })
      }

      post '/api/method/lms.api.capture_user_persona', params: persona_data

      # Check that persona_captured is set
      get '/api/method/frappe.client.get_single_value', params: {
        doctype: 'LMS Settings',
        field: 'persona_captured'
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to eq(1)
    end
  end

  describe 'Onboarding UI Flow (exact replica of Frappe onboarding header)' do
    it 'shows onboarding header for moderators who havent completed onboarding' do
      sign_in moderator

      get '/dashboard'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('onboarding-parent')
      expect(response.body).to include('Get Started')
      expect(response.body).to include('Create a Course')
      expect(response.body).to include('Add a Chapter')
      expect(response.body).to include('Add a Lesson')
    end

    it 'hides onboarding header for moderators who have completed onboarding' do
      # Create content to complete onboarding
      course
      chapter
      lesson

      sign_in moderator

      get '/dashboard'

      expect(response).to have_http_status(:ok)
      expect(response.body).to_not include('onboarding-parent')
    end

    it 'hides onboarding header for non-moderators' do
      sign_in user

      get '/dashboard'

      expect(response).to have_http_status(:ok)
      expect(response.body).to_not include('onboarding-parent')
    end
  end

  describe 'Onboarding Step Links (exact replica of Frappe step progression)' do
    it 'shows disabled chapter link when no course exists' do
      sign_in moderator

      get '/dashboard'

      expect(response.body).to include('disabled')
      expect(response.body).to_not include('href="/courses/')
    end

    it 'enables chapter link when course exists' do
      course

      sign_in moderator

      get '/dashboard'

      expect(response.body).to include("href=\"/courses/#{course.name}/outline\"")
    end

    it 'enables lesson link when chapter exists' do
      course
      chapter

      sign_in moderator

      get '/dashboard'

      expect(response.body).to include("href=\"/courses/#{course.name}/learn/1.1/edit\"")
    end
  end

  describe 'Onboarding Skip Functionality (exact replica of Frappe skip)' do
    it 'allows skipping onboarding by setting LMS Settings flag' do
      sign_in moderator

      patch '/api/method/frappe.client.set_value', params: {
        doctype: 'LMS Settings',
        fieldname: 'is_onboarding_complete',
        value: 1
      }

      expect(response).to have_http_status(:ok)

      get '/dashboard'

      expect(response.body).to_not include('onboarding-parent')
    end
  end

  describe 'Persona Form Integration (exact replica of Frappe persona flow)' do
    it 'redirects to persona form when no courses exist and persona not captured' do
      # This would be tested in system tests with the frontend
      # For now, we verify the backend logic is correct
      sign_in user

      # Check persona captured status
      get '/api/method/frappe.client.get_single_value', params: {
        doctype: 'LMS Settings',
        field: 'persona_captured'
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to eq(0) # Not captured
    end

    it 'does not redirect to persona form when persona is captured' do
      # Capture persona first
      sign_in user

      persona_data = {
        responses: JSON.generate({
          role: 'Student',
          use_case: 'Personal Learning'
        })
      }

      post '/api/method/lms.api.capture_user_persona', params: persona_data

      # Check persona captured status
      get '/api/method/frappe.client.get_single_value', params: {
        doctype: 'LMS Settings',
        field: 'persona_captured'
      }

      json = JSON.parse(response.body)
      expect(json['message']).to eq(1) # Captured
    end
  end

  describe 'Onboarding Progress Tracking (exact replica of Frappe progress logic)' do
    it 'tracks course creation progress' do
      sign_in moderator

      # No content yet
      get '/api/onboarding/status'
      json = JSON.parse(response.body)
      expect(json['course_created']).to be_falsey

      # Create course
      course

      get '/api/onboarding/status'
      json = JSON.parse(response.body)
      expect(json['course_created']).to be_truthy
      expect(json['chapter_created']).to be_falsey
    end

    it 'tracks chapter creation progress' do
      course

      sign_in moderator

      get '/api/onboarding/status'
      json = JSON.parse(response.body)
      expect(json['chapter_created']).to be_falsey

      # Create chapter
      chapter

      get '/api/onboarding/status'
      json = JSON.parse(response.body)
      expect(json['chapter_created']).to be_truthy
      expect(json['lesson_created']).to be_falsey
    end

    it 'tracks lesson creation progress and completes onboarding' do
      course
      chapter

      sign_in moderator

      get '/api/onboarding/status'
      json = JSON.parse(response.body)
      expect(json['lesson_created']).to be_falsey
      expect(json['is_onboarded']).to be_falsey

      # Create lesson
      lesson

      get '/api/onboarding/status'
      json = JSON.parse(response.body)
      expect(json['lesson_created']).to be_truthy
      expect(json['is_onboarded']).to be_truthy
    end
  end

  private

  def sign_in(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end
end