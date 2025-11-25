require 'rails_helper'

RSpec.describe 'Onboarding UI Flow', type: :system do
  let(:user) { create(:user, email: 'student@example.com', full_name: 'Test Student') }
  let(:moderator) { create(:user, email: 'moderator@example.com', full_name: 'Test Moderator') }

  before do
    driven_by(:selenium_chrome_headless)
    moderator.add_role("Moderator")
  end

  describe 'Persona Form Flow (exact replica of Frappe persona onboarding)' do
    it 'shows persona form for system managers with no courses' do
      # Make user a system manager (similar to Frappe's logic)
      user.update(is_admin: true)

      sign_in user

      visit '/courses'

      # Should redirect to persona form
      expect(page).to have_current_path('/persona')
      expect(page).to have_content('Help us understand your needs')
      expect(page).to have_content('What is your use case for Frappe Learning?')
      expect(page).to have_content('What best describes your role?')
    end

    it 'captures persona and redirects to courses' do
      user.update(is_admin: true)

      sign_in user

      visit '/persona'

      # Fill out persona form
      select 'Personal Learning', from: 'What is your use case for Frappe Learning?'
      select 'Student', from: 'What best describes your role?'

      click_button 'Submit and Continue'

      # Should redirect to courses
      expect(page).to have_current_path('/courses')

      # Persona should be captured
      user.reload
      expect(user.persona_role).to eq('Student')
      expect(user.persona_use_case).to eq('Personal Learning')
      expect(user.persona_captured_at).to be_present
    end

    it 'allows skipping persona form' do
      user.update(is_admin: true)

      sign_in user

      visit '/persona'

      click_link 'Skip'

      # Should redirect to courses
      expect(page).to have_current_path('/courses')
    end
  end

  describe 'Onboarding Header Display (exact replica of Frappe onboarding header)' do
    it 'shows onboarding header for moderators who havent completed setup' do
      sign_in moderator

      visit '/dashboard'

      # Should show onboarding header
      expect(page).to have_content('Get Started')
      expect(page).to have_content('Lets start setting up your content on the LMS')
      expect(page).to have_content('Create a Course')
      expect(page).to have_content('Add a Chapter')
      expect(page).to have_content('Add a Lesson')
      expect(page).to have_button('Skip')
    end

    it 'shows checkmarks for completed steps' do
      # Create course
      course = create(:course, instructor: moderator)

      sign_in moderator

      visit '/dashboard'

      # Course creation should be checked
      expect(page).to have_css('.icon-green-check-circled')

      # Chapter and lesson should not be checked
      expect(page).to have_css('.icon-disabled-check')
    end

    it 'enables step links based on progress' do
      # Create course and chapter
      course = create(:course, instructor: moderator)
      chapter = create(:course_chapter, course: course)

      sign_in moderator

      visit '/dashboard'

      # Should have link to chapter outline
      expect(page).to have_link('Add a Chapter', href: "/courses/#{course.name}/outline")

      # Should have link to lesson creation
      expect(page).to have_link('Add a Lesson', href: "/courses/#{course.name}/learn/1.1/edit")
    end

    it 'hides onboarding header when complete' do
      # Complete onboarding by creating content
      course = create(:course, instructor: moderator)
      chapter = create(:course_chapter, course: course)
      lesson = create(:course_lesson, course_chapter: chapter, course: course)

      sign_in moderator

      visit '/dashboard'

      # Should not show onboarding header
      expect(page).to_not have_content('Get Started')
      expect(page).to_not have_content('Create a Course')
    end

    it 'allows skipping onboarding' do
      sign_in moderator

      visit '/dashboard'

      click_button 'Skip'

      # Should reload and hide onboarding
      expect(page).to_not have_content('Get Started')
    end
  end

  describe 'Onboarding Step Progression (exact replica of Frappe step flow)' do
    it 'starts with course creation step' do
      sign_in moderator

      visit '/dashboard'

      # Create Course should be the first enabled step
      expect(page).to have_link('Create a Course', href: '/courses/new-course/edit')

      # Other steps should be disabled
      expect(page).to have_css('a[disabled]')
    end

    it 'unlocks chapter creation after course creation' do
      course = create(:course, instructor: moderator)

      sign_in moderator

      visit '/dashboard'

      # Chapter link should be enabled
      expect(page).to have_link('Add a Chapter', href: "/courses/#{course.name}/outline")
    end

    it 'unlocks lesson creation after chapter creation' do
      course = create(:course, instructor: moderator)
      chapter = create(:course_chapter, course: course)

      sign_in moderator

      visit '/dashboard'

      # Lesson link should be enabled
      expect(page).to have_link('Add a Lesson', href: "/courses/#{course.name}/learn/1.1/edit")
    end

    it 'completes onboarding after lesson creation' do
      course = create(:course, instructor: moderator)
      chapter = create(:course_chapter, course: course)
      lesson = create(:course_lesson, course_chapter: chapter, course: course)

      sign_in moderator

      visit '/dashboard'

      # Onboarding should be complete
      expect(page).to_not have_content('Get Started')
      expect(page).to have_content('Welcome to Your Learning Dashboard')
    end
  end

  private

  def sign_in(user)
    visit '/users/sign_in'
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password'
    click_button 'Sign In'
  end
end