require 'rails_helper'

RSpec.describe 'Api::Courses', type: :request do
  let(:user) { create(:user) }
  let(:instructor) { create(:user, email: 'instructor@example.com') }
  let(:course) { create(:course, title: 'Test Course', instructors: [instructor]) }
  let(:chapter) { create(:course_chapter, course: course) }
  let(:lesson) { create(:course_lesson, course_chapter: chapter, course: course) }

  before do
    sign_in user
  end

  describe 'GET /api/courses' do
    before do
      create_list(:course, 3, published: true)
      create(:course, published: false)
    end

    it 'returns published courses' do
      get '/api/courses'
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['courses'].count).to eq(3)
      expect(json['courses'].all? { |c| c['published'] }).to be_truthy
    end

    it 'includes course details' do
      get '/api/courses'
      
      json = JSON.parse(response.body)
      course_data = json['courses'].first
      
      expect(course_data).to include(
        'id', 'name', 'title', 'short_introduction', 
        'description', 'image', 'published'
      )
    end

    it 'supports pagination' do
      get '/api/courses', params: { page: 1, limit: 2 }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['courses'].count).to be <= 2
    end

    it 'supports filtering by category' do
      category = create(:lms_category, title: 'Programming')
      create(:course, published: true, category: category)
      
      get '/api/courses', params: { category: category.id }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['courses'].all? { |c| c['category_id'] == category.id }).to be_truthy
    end
  end

  describe 'GET /api/courses/:course' do
    before do
      course.update(published: true)
    end

    it 'returns course details' do
      get "/api/courses/#{course.name}"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      
      expect(json).to include(
        'id' => course.id,
        'name' => course.name,
        'title' => course.title
      )
    end

    it 'includes course chapters and lessons' do
      get "/api/courses/#{course.name}"
      
      json = JSON.parse(response.body)
      expect(json['chapters']).to be_present
      expect(json['chapters'].first['lessons']).to be_present
    end

    it 'includes enrollment status for authenticated user' do
      create(:enrollment, user: user, course: course)
      
      get "/api/courses/#{course.name}"
      
      json = JSON.parse(response.body)
      expect(json['is_enrolled']).to be_truthy
      expect(json['progress_percentage']).to be_present
    end

    it 'returns 404 for non-existent course' do
      get '/api/courses/non-existent'
      
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for unpublished course for non-instructor' do
      course.update(published: false)
      
      get "/api/courses/#{course.name}"
      
      expect(response).to have_http_status(:not_found)
    end

    it 'allows instructor to view unpublished course' do
      course.update(published: false)
      sign_in instructor
      
      get "/api/courses/#{course.name}"
      
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /api/courses' do
    let(:valid_attributes) do
      {
        title: 'New Course',
        short_introduction: 'A great course',
        description: 'Detailed description',
        video_link: 'https://example.com/video'
      }
    end

    context 'when user is authorized' do
      before do
        user.update(roles: ['instructor']) # or however you handle permissions
        sign_in user
      end

      it 'creates a new course' do
        expect do
          post '/api/courses', params: { course: valid_attributes }
        end.to change(Course, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['title']).to eq('New Course')
      end

      it 'assigns current user as instructor' do
        post '/api/courses', params: { course: valid_attributes }
        
        new_course = Course.last
        expect(new_course.instructors).to include(user)
      end

      it 'returns validation errors for invalid data' do
        post '/api/courses', params: { course: { title: '' } }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context 'when user is not authorized' do
      it 'returns unauthorized status' do
        post '/api/courses', params: { course: valid_attributes }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/courses/:course' do
    let(:update_attributes) do
      {
        title: 'Updated Course Title',
        description: 'Updated description'
      }
    end

    context 'when user is course instructor' do
      before do
        sign_in instructor
      end

      it 'updates the course' do
        put "/api/courses/#{course.name}", params: { course: update_attributes }
        
        expect(response).to have_http_status(:ok)
        course.reload
        expect(course.title).to eq('Updated Course Title')
        expect(course.description).to eq('Updated description')
      end

      it 'returns validation errors for invalid data' do
        put "/api/courses/#{course.name}", params: { course: { title: '' } }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context 'when user is not course instructor' do
      it 'returns unauthorized status' do
        put "/api/courses/#{course.name}", params: { course: update_attributes }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'returns 404 for non-existent course' do
      sign_in instructor
      put '/api/courses/non-existent', params: { course: update_attributes }
      
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/courses/:course' do
    context 'when user is course instructor' do
      before do
        sign_in instructor
      end

      it 'deletes the course' do
        course_id = course.id
        
        expect do
          delete "/api/courses/#{course.name}"
        end.to change(Course, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
        expect { Course.find(course_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'deletes associated data' do
        enrollment = create(:enrollment, course: course)
        
        delete "/api/courses/#{course.name}"
        
        expect { Enrollment.find(enrollment.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when user is not course instructor' do
      it 'returns unauthorized status' do
        delete "/api/courses/#{course.name}"
        
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'returns 404 for non-existent course' do
      sign_in instructor
      delete '/api/courses/non-existent'
      
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/courses/:course/enroll' do
    before do
      course.update(published: true)
    end

    it 'enrolls user in course' do
      expect do
        post "/api/courses/#{course.name}/enroll"
      end.to change(user.enrollments, :count).by(1)
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to include('enrolled')
    end

    it 'prevents duplicate enrollment' do
      create(:enrollment, user: user, course: course)
      
      post "/api/courses/#{course.name}/enroll"
      
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to include('already enrolled')
    end

    it 'prevents enrollment in unpublished course' do
      course.update(published: false)
      
      post "/api/courses/#{course.name}/enroll"
      
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to include('not available')
    end

    context 'when enrollment requires payment' do
      before do
        course.update(paid: true, price: 99.99)
      end

      it 'requires payment for paid course' do
        post "/api/courses/#{course.name}/enroll"
        
        expect(response).to have_http_status(:payment_required)
        json = JSON.parse(response.body)
        expect(json['payment_required']).to be_truthy
        expect(json['price']).to eq(99.99)
      end
    end
  end

  describe 'GET /api/courses/:course/progress' do
    let!(:enrollment) { create(:enrollment, user: user, course: course) }

    it 'returns user progress in course' do
      create(:lesson_progress, user: user, lesson: lesson, status: 'Complete')
      
      get "/api/courses/#{course.name}/progress"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['progress_percentage']).to be > 0
      expect(json['lessons_completed']).to eq(1)
      expect(json['total_lessons']).to eq(1)
    end

    it 'returns 404 for non-enrolled user' do
      other_user = create(:user)
      sign_in other_user
      
      get "/api/courses/#{course.name}/progress"
      
      expect(response).to have_http_status(:not_found)
    end
  end

  # Helper methods for authentication
  def sign_in(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end
end