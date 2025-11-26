require 'rails_helper'

RSpec.describe 'Batch Creation', type: :system do
  let(:instructor) { create(:user, email: 'instructor@example.com', full_name: 'Test Instructor') }
  let(:evaluator) { create(:user, email: 'evaluator@example.com', full_name: 'Test Evaluator') }
  let(:student) { create(:user, email: 'student@example.com', full_name: 'Test Student') }
  let(:course) { create(:course, title: 'Test Course', instructor: instructor) }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in instructor
  end

  it 'creates a new batch with all fields and manages students' do
    # Navigate to batches
    visit '/batches'

    # Create a new batch
    click_button 'Create'

    # Fill in batch details
    fill_in 'Title', with: 'Test Batch'
    fill_in 'Start Date', with: '2030-10-01'
    fill_in 'End Date', with: '2030-10-31'
    fill_in 'Start Time', with: '10:00'
    fill_in 'End Time', with: '11:00'
    fill_in 'Timezone', with: 'IST'
    fill_in 'Seat Count', with: '10'

    check 'Published'

    fill_in 'Short Description', with: 'Test Batch Short Description to test the UI'

    fill_in 'Description', with: 'Test Batch Description. I need a very big description to test the UI. This is a very big description. It contains more than once sentence. Its meant to be this long as this is a UI test. Its unbearably long and I am not sure why I am typing this much. I am just going to keep typing until I feel like its long enough. I think its long enough now. I am going to stop typing now.'

    # Select course
    select course.title, from: 'Course'

    # Select instructor
    select instructor.full_name, from: 'Instructor'

    # Save the batch
    click_button 'Save'

    # Verify batch was created
    expect(page).to have_content('Test Batch')
    expect(page).to have_content('Test Batch Short Description to test the UI')
    expect(page).to have_content('01 Oct 2030 - 31 Oct 2030')
    expect(page).to have_content('10:00 AM - 11:00 AM')
    expect(page).to have_content('IST')
    expect(page).to have_content('10 Seats Left')

    # Click on batch details
    click_link 'Test Batch'

    # Verify detailed view
    expect(page).to have_content('Test Batch')
    expect(page).to have_content('Test Batch Short Description to test the UI')
    expect(page).to have_content('01 Oct 2030 - 31 Oct 2030')
    expect(page).to have_content('10:00 AM - 11:00 AM')
    expect(page).to have_content('IST')
    expect(page).to have_content('10 Seats Left')

    expect(page).to have_content('Test Batch Description. I need a very big description to test the UI. This is a very big description. It contains more than once sentence. Its meant to be this long as this is a UI test. Its unbearably long and I am not sure why I am typing this much. I am just going to keep typing until I feel like its long enough. I think its long enough now. I am going to stop typing now.')

    # Manage batch - add student
    click_button 'Manage Batch'
    click_button 'Students'
    click_button 'Add'

    within('.modal') do
      select student.full_name, from: 'Student'
      click_button 'Submit'
    end

    # Verify student was added and seat count decreased
    expect(page).to have_content(student.full_name)
    expect(page).to have_content('9 Seats Left')
  end

  private

  def sign_in(user)
    visit '/users/sign_in'
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password'
    click_button 'Sign In'
  end
end
