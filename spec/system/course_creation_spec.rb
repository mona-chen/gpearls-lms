require 'rails_helper'

RSpec.describe 'Course Creation', type: :system do
  let(:user) { create(:user, email: 'instructor@example.com', full_name: 'Test Instructor') }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
  end

  it 'creates a new course with all fields' do
    visit '/courses/new'

    # Fill in basic course information
    fill_in 'Title', with: 'Test Course'
    fill_in 'Short Introduction', with: 'Test Course Short Introduction to test the UI'
    fill_in 'Description', with: 'Test Course Description. I need a very big description to test the UI. This is a very big description. It contains more than once sentence. Its meant to be this long as this is a UI test. Its unbearably long and I am not sure why I am typing this much. I am just going to keep typing until I feel like its long enough. I think its long enough now. I am going to stop typing now.'

    # Upload course image
    attach_file 'course_image', Rails.root.join('spec/fixtures/files/test_image.png')

    # Add video link
    fill_in 'Video Link', with: 'https://www.youtube.com/embed/-LPmw2Znl2c'

    # Add tags
    fill_in 'Tags', with: 'Learning,Frappe,ERPNext'

    # Select category
    select 'Technology', from: 'Category'

    # Set as published
    check 'Published'

    # Set published date
    fill_in 'Published On', with: '2021-01-01'

    # Save the course
    click_button 'Save'

    # Verify course was created
    expect(page).to have_content('Test Course')
    expect(page).to have_content('Test Course Short Introduction to test the UI')

    # Add chapter
    click_button 'Add Chapter'

    within('.modal') do
      fill_in 'Title', with: 'Test Chapter'
      click_button 'Create'
    end

    # Verify chapter was added
    expect(page).to have_content('Test Chapter')

    # Add lesson
    click_button 'Add Lesson'

    # Fill in lesson details
    fill_in 'Title', with: 'Test Lesson'
    fill_in 'Content', with: 'This is an extremely big paragraph that is meant to test the UI. This is a very long paragraph. It contains more than once sentence. Its meant to be this long as this is a UI test. Its unbearably long and I am not sure why I am typing this much. I am just going to keep typing until I feel like its long enough. I think its long enough now. I am going to stop typing now.'

    click_button 'Save'

    # Verify lesson was created
    expect(page).to have_content('Test Lesson')
    expect(page).to have_content('This is an extremely big paragraph')

    # Add discussion
    click_link 'Community'
    click_button 'New Question'

    within('.modal') do
      fill_in 'Title', with: 'Test Discussion'
      fill_in 'Content', with: 'This is a test discussion. This will check if the UI is working properly.'
      click_button 'Post'
    end

    # Verify discussion was posted
    expect(page).to have_content('Test Discussion')
    expect(page).to have_content('This is a test discussion')

    # Add a reply
    fill_in 'Reply', with: 'This is a test comment. This will check if the UI is working properly.'
    click_button 'Post Reply'

    expect(page).to have_content('This is a test comment')
  end

  private

  def sign_in(user)
    visit '/users/sign_in'
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password'
    click_button 'Sign In'
  end
end
