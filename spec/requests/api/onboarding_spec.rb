require 'rails_helper'

RSpec.describe 'API::Onboarding', type: :request do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :moderator) }
  let(:token) { generate_jwt_token(user) }
  let(:moderator_token) { generate_jwt_token(moderator) }
  let(:course) { create(:course) }
  let(:chapter) { create(:chapter, course: course) }
  let(:lesson) { create(:lesson, chapter: chapter) }
  let(:quiz) { create(:quiz, course: course) }

  describe 'GET /api/onboarding/status' do
    context 'when user is not authenticated' do
      it 'returns unauthorized' do
        get '/api/onboarding/status'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is not a moderator' do
      it 'returns onboarded status immediately' do
        get '/api/onboarding/status', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['is_onboarded']).to be true
      end
    end

    context 'when user is a moderator' do
      before do
        LmsSetting.set_onboarding_complete(false)
      end

      context 'with no content created' do
        it 'returns not onboarded with all flags false' do
          get '/api/onboarding/status', headers: { 'Authorization' => "Bearer #{moderator_token}" }

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)
          expect(json_response['is_onboarded']).to be false
          expect(json_response['course_created']).to be false
          expect(json_response['chapter_created']).to be false
          expect(json_response['lesson_created']).to be false
          expect(json_response['quiz_created']).to be false
          expect(json_response['first_course']).to be_nil
        end
      end

      context 'with only course created' do
        before { course }

        it 'returns partial onboarding status' do
          get '/api/onboarding/status', headers: { 'Authorization' => "Bearer #{moderator_token}" }

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)
          expect(json_response['is_onboarded']).to be false
          expect(json_response['course_created']).to be true
          expect(json_response['chapter_created']).to be false
          expect(json_response['lesson_created']).to be false
          expect(json_response['quiz_created']).to be false
          expect(json_response['first_course']).to eq(course.title)
        end
      end

      context 'with course and chapter created' do
        before do
          course
          chapter
        end

        it 'returns partial onboarding status' do
          get '/api/onboarding/status', headers: { 'Authorization' => "Bearer #{moderator_token}" }

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)
          expect(json_response['is_onboarded']).to be false
          expect(json_response['course_created']).to be true
          expect(json_response['chapter_created']). to be true
          expect(json_response['lesson_created']).to be false
          expect(json_response['quiz_created']).to be false
          expect(json_response['first_course']).to eq(course.title)
        end
      end

      context 'with course, chapter, and lesson created' do
        before do
          course
          chapter
          lesson
        end

        it 'returns partial onboarding status' do
          get '/api/onboarding/status', headers: { 'Authorization' => "Bearer #{moderator_token}" }

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)
          expect(json_response['is_onboarded']).to be false
          expect(json_response['course_created']).to be true
          expect(json_response['chapter_created']).to be true
          expect(json_response['lesson_created']).to be true
          expect(json_response['quiz_created']).to be false
          expect(json_response['first_course']).to eq(course.title)
        end
      end

      context 'with all content created' do
        before do
          course
          chapter
          lesson
          quiz
        end

        it 'returns fully onboarded status' do
          get '/api/onboarding/status', headers: { 'Authorization' => "Bearer #{moderator_token}" }

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)
          expect(json_response['is_onboarded']).to be true
          expect(json_response['course_created']).to be true
          expect(json_response['chapter_created']).to be true
          expect(json_response['lesson_created']).to be true
          expect(json_response['quiz_created']).to be true
          expect(json_response['first_course']).to eq(course.title)
        end

        it 'updates LMS Settings to mark onboarding complete' do
          expect(LmsSetting.is_onboarding_complete).to be false

          get '/api/onboarding/status', headers: { 'Authorization' => "Bearer #{moderator_token}" }

          expect(LmsSetting.is_onboarding_complete).to be true
        end
      end
    end
  end

  describe 'GET /api/onboarding/first-course' do
    context 'when user is not authenticated' do
      it 'returns unauthorized' do
        get '/api/onboarding/first-course'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when no courses exist' do
      it 'returns nil' do
        get '/api/onboarding/first-course', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['first_course']).to be_nil
      end
    end

    context 'when courses exist' do
      before { course }

      it 'returns the first course title' do
        get '/api/onboarding/first-course', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['first_course']).to eq(course.title)
      end
    end
  end

  describe 'GET /api/onboarding/first-batch' do
    let(:batch) { create(:batch) }

    context 'when user is not authenticated' do
      it 'returns unauthorized' do
        get '/api/onboarding/first-batch'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when no batches exist' do
      it 'returns nil' do
        get '/api/onboarding/first-batch', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['first_batch']).to be_nil
      end
    end

    context 'when batches exist' do
      before { batch }

      it 'returns the first batch title' do
        get '/api/onboarding/first-batch', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['first_batch']).to eq(batch.title)
      end
    end
  end

  describe 'POST /api/onboarding/handle_method (Frappe Compatibility)' do
    context 'when handling is_onboarding_complete method' do
      it 'returns onboarding status' do
        post '/api/onboarding/handle_method',
             params: { method_path: 'lms.onboarding.is_onboarding_complete' },
             headers: { 'Authorization' => "Bearer #{moderator_token}" }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('is_onboarded')
        expect(json_response).to have_key('course_created')
        expect(json_response).to have_key('chapter_created')
        expect(json_response).to have_key('lesson_created')
        expect(json_response).to have_key('quiz_created')
      end
    end

    context 'when handling get_first_course method' do
      before { course }

      it 'returns first course name' do
        post '/api/onboarding/handle_method',
             params: { method_path: 'lms.onboarding.get_first_course' },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response).to eq(course.title)
      end
    end

    context 'when handling set_value method for onboarding completion' do
      it 'sets onboarding complete status' do
        expect(LmsSetting.is_onboarding_complete).to be false

        post '/api/onboarding/handle_method',
             params: {
               method_path: 'frappe.client.set_value',
               doctype: 'LMS Settings',
               fieldname: 'is_onboarding_complete',
               value: 1
             },
             headers: { 'Authorization' => "Bearer #{moderator_token}" }

        expect(response).to have_http_status(:success)
        expect(LmsSetting.is_onboarding_complete).to be true
      end
    end

    context 'when handling unknown method' do
      it 'returns error' do
        post '/api/onboarding/handle_method',
             params: { method_path: 'unknown.method' },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unknown method')
      end
    end

    context 'when handling set_value with invalid parameters' do
      it 'returns error' do
        post '/api/onboarding/handle_method',
             params: {
               method_path: 'frappe.client.set_value',
               doctype: 'Wrong Settings',
               fieldname: 'wrong_field',
               value: 1
             },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid parameters')
      end
    end
  end
end
