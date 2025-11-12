#!/usr/bin/env ruby

# Comprehensive sample data creation for LMS testing
# This script populates all necessary tables with realistic test data

require_relative 'config/environment'

puts "🌱 CREATING COMPREHENSIVE LMS SAMPLE DATA"
puts "=" * 50

# Clean up existing data first
puts "Cleaning up existing data..."
# Delete in reverse dependency order (children first, then parents)
# Use basic destroy_all for tables that exist
begin
  LmsQuizSubmission.destroy_all
rescue => e
  puts "Warning: Could not clean LmsQuizSubmission: #{e.message}"
end

begin
  Payment.destroy_all
rescue => e
  puts "Warning: Could not clean Payment: #{e.message}"
end

LmsEnrollment.destroy_all
BatchEnrollment.destroy_all
Notification.destroy_all
CourseProgress.destroy_all
Course.destroy_all
Batch.destroy_all
User.destroy_all

# Create categories first
puts "Creating categories..."
categories = []

programming_category = LmsCategory.find_or_create_by!(name: 'Programming') do |c|
  c.description = 'Learn various programming languages and development skills'
  c.parent_category = 'Technology'
  c.icon = 'code'
  c.color = '#3B82F6'
  c.position = 1
  c.is_active = true
end
categories << programming_category

data_science_category = LmsCategory.find_or_create_by!(name: 'Data Science') do |c|
  c.description = 'Master data analysis, machine learning, and AI technologies'
  c.parent_category = 'Technology'
  c.icon = 'database'
  c.color = '#8B5CF6'
  c.position = 2
  c.is_active = true
end
categories << data_science_category

web_dev_category = LmsCategory.find_or_create_by!(name: 'Web Development') do |c|
  c.description = 'Build modern web applications with frontend and backend technologies'
  c.parent_category = 'Technology'
  c.icon = 'laptop-code'
  c.color = '#10B981'
  c.position = 3
  c.is_active = true
end
categories << web_dev_category

puts "✅ Created #{categories.count} categories"

# Create test users
puts "Creating test users..."
users = []

# Admin/Creator user
admin_user = User.find_or_create_by!(email: 'admin@lms.com') do |u|
  u.username = 'admin'
  u.full_name = 'Admin User'
  u.first_name = 'Admin'
  u.last_name = 'User'
  u.password = 'password123'
  u.role = 'LMS Student'
  u.user_type = 'Administrator'
end
users << admin_user

# Instructor user
instructor_user = User.find_or_create_by!(email: 'instructor@lms.com') do |u|
  u.username = 'instructor'
  u.full_name = 'John Instructor'
  u.first_name = 'John'
  u.last_name = 'Instructor'
  u.password = 'password123'
  u.role = 'LMS Student'
  u.user_type = 'Course Creator'
end
users << instructor_user

# Regular students
student_emails = [ 'alice@lms.com', 'bob@lms.com', 'charlie@lms.com', 'diana@lms.com' ]
student_emails.each do |email|
  name = email.split('@').first.capitalize
  username = email.split('@').first
  # Ensure username is at least 4 characters
  username = username + username while username.length < 4
  username = username[0..9] # Max 10 characters

  user = User.find_or_create_by!(email: email) do |u|
    u.username = username
    u.full_name = "#{name} Student"
    u.first_name = name
    u.last_name = 'Student'
    u.password = 'password123'
    u.role = 'LMS Student'
    u.user_type = 'LMS Student'
  end
  users << user
end

puts "✅ Created #{users.count} users"

# Create courses
puts "Creating courses..."
courses = []

ruby_course = Course.find_or_create_by!(title: 'Ruby Programming Fundamentals') do |c|
  c.description = 'Learn the fundamentals of Ruby programming language'
  c.short_introduction = 'A comprehensive introduction to Ruby'
  c.tags = 'ruby,programming,beginner'
  c.category = programming_category.name
  c.status = 'Approved'
  c.published = true
  c.certificate_enabled = true
  c.instructor = instructor_user
end
courses << ruby_course

python_course = Course.find_or_create_by!(title: 'Python for Data Science') do |c|
  c.description = 'Master Python programming for data analysis and machine learning'
  c.short_introduction = 'Python programming for data science applications'
  c.tags = 'python,data-science,machine-learning'
  c.category = data_science_category.name
  c.status = 'Approved'
  c.published = true
  c.price = 99.99
  c.currency = 'USD'
  c.certificate_enabled = true
  c.instructor = instructor_user
end
courses << python_course

web_dev_course = Course.find_or_create_by!(title: 'Full Stack Web Development') do |c|
  c.description = 'Build modern web applications with HTML, CSS, JavaScript, and frameworks'
  c.short_introduction = 'Complete web development bootcamp'
  c.tags = 'web-development,javascript,html,css'
  c.category = web_dev_category.name
  c.status = 'Approved'
  c.published = true
  c.price = 149.99
  c.currency = 'USD'
  c.certificate_enabled = true
  c.instructor = instructor_user
end
courses << web_dev_course

puts "✅ Created #{courses.count} courses"

# Create chapters and lessons for Ruby course
puts "Creating chapters and lessons..."

# Ruby course chapters
ruby_chapter1 = CourseChapter.find_or_create_by!(name: 'ruby-intro-chapter', course: ruby_course) do |ch|
  ch.title = 'Introduction to Ruby'
  ch.idx = 1
  ch.owner = instructor_user.email
  ch.creation = Time.current
  ch.modified = Time.current
  ch.modified_by = instructor_user.email
end

ruby_lesson1 = CourseLesson.find_or_create_by!(name: 'ruby-lesson-1', chapter: ruby_chapter1, course: ruby_course) do |l|
  l.title = 'Getting Started with Ruby'
  l.idx = 1
  l.content = 'Welcome to Ruby programming! In this lesson, we will cover the basics of Ruby syntax and get you set up for success.'
  l.owner = instructor_user.email
  l.creation = Time.current
  l.modified = Time.current
  l.modified_by = instructor_user.email
end

ruby_lesson2 = CourseLesson.find_or_create_by!(name: 'ruby-lesson-2', chapter: ruby_chapter1, course: ruby_course) do |l|
  l.title = 'Variables and Data Types'
  l.idx = 2
  l.content = 'Learn about Ruby variables, strings, numbers, booleans, and other fundamental data types.'
  l.owner = instructor_user.email
  l.creation = Time.current
  l.modified = Time.current
  l.modified_by = instructor_user.email
end

ruby_chapter2 = CourseChapter.find_or_create_by!(name: 'ruby-control-structures', course: ruby_course) do |ch|
  ch.title = 'Control Structures'
  ch.idx = 2
  ch.owner = instructor_user.email
  ch.creation = Time.current
  ch.modified = Time.current
  ch.modified_by = instructor_user.email
end

ruby_lesson3 = CourseLesson.find_or_create_by!(name: 'ruby-lesson-3', chapter: ruby_chapter2, course: ruby_course) do |l|
  l.title = 'Conditional Statements'
  l.idx = 1
  l.content = 'Master if/else statements, case expressions, and ternary operators in Ruby.'
  l.owner = instructor_user.email
  l.creation = Time.current
  l.modified = Time.current
  l.modified_by = instructor_user.email
end

puts "✅ Created chapters and lessons for Ruby course"

# Create enrollments
puts "Creating course enrollments..."
enrollments = []

# Enroll students in courses
students = users.select { |u| u.user_type == 'LMS Student' }

students.each do |student|
  courses.each do |course|
    enrollment = LmsEnrollment.find_or_create_by!(user: student, course: course) do |e|
      e.progress_percentage = rand(0..100)
      e.status = e.progress_percentage == 100 ? "Completed" : "Active"
    end
    enrollments << enrollment
  end
end

puts "✅ Created #{enrollments.count} course enrollments"

# Create lesson progress
puts "Creating lesson progress records..."
progress_records = []

students.each do |student|
  [ ruby_lesson1, ruby_lesson2, ruby_lesson3 ].each do |lesson|
    progress = LessonProgress.find_or_create_by!(user: student, lesson: lesson) do |p|
      p.progress = rand(0..100)
      p.completed = p.progress == 100
      p.last_accessed_at = rand(1..30).days.ago
    end
    progress_records << progress
  end
end

puts "✅ Created #{progress_records.count} lesson progress records"

# Create batches
puts "Creating batches..."
batches = []

ruby_batch = Batch.find_or_create_by!(title: 'Ruby Programming Batch 2025') do |b|
  b.description = 'First batch for Ruby programming course'
  b.start_date = 1.month.from_now
  b.end_date = 3.months.from_now
  b.start_time = '09:00:00'
  b.end_time = '17:00:00'
  b.timezone = 'UTC'
  b.status = 'Active'
  b.published = true
  b.allow_self_enrollment = true
  b.max_students = 20
  b.instructor = instructor_user
  b.additional_info = 'Weekly classes on Monday and Wednesday'
  b.course_id = ruby_course.id  # Required by schema
end
batches << ruby_batch

python_batch = Batch.find_or_create_by!(title: 'Python Data Science Batch 2025') do |b|
  b.description = 'Batch for Python data science course'
  b.start_date = 2.months.from_now
  b.end_date = 4.months.from_now
  b.start_time = '10:00:00'
  b.end_time = '16:00:00'
  b.timezone = 'UTC'
  b.status = 'Active'
  b.published = true
  b.allow_self_enrollment = true
  b.max_students = 25
  b.instructor = instructor_user
  b.additional_info = 'Advanced Python for data science'
  b.course_id = python_course.id  # Required by schema
end
batches << python_batch

puts "✅ Created #{batches.count} batches"

# Create batch-course associations
puts "Creating batch-course associations..."
# Temporarily commented out due to schema/model inconsistencies
batch_courses = []
puts "✅ Skipped batch-course associations due to schema issues"

# Create batch enrollments
puts "Creating batch enrollments..."
batch_enrollments = []

students.first(3).each do |student|
  batch_enrollments << BatchEnrollment.find_or_create_by!(user: student, batch: ruby_batch)
end

students.last(2).each do |student|
  batch_enrollments << BatchEnrollment.find_or_create_by!(user: student, batch: python_batch)
end

puts "✅ Created #{batch_enrollments.count} batch enrollments"

# Create quizzes and questions
puts "Creating quizzes and questions..."
# Temporarily skipped due to model/schema mismatches
quizzes = []
puts "✅ Skipped quiz creation due to schema issues"

# Create discussions
puts "Creating discussions..."
# Temporarily skipped due to missing discussions table
discussions = []
puts "✅ Skipped discussion creation due to missing table"

# Create programs
puts "Creating programs..."
# Temporarily skipped due to schema issues
programs = []
puts "✅ Skipped program creation due to schema issues"

# Create notifications
puts "Creating notifications..."
notifications = []

students.each do |student|
  notification = Notification.find_or_create_by!(
    user: student,
    subject: 'Welcome to the LMS!',
    email_content: 'Welcome to our Learning Management System. Start exploring courses today!'
  ) do |n|
    n.type = 'welcome'
    n.read = false
  end
  notifications << notification
end

puts "✅ Created #{notifications.count} notifications"

# Create LMS settings
puts "Creating LMS settings..."
# Temporarily skipped due to schema mismatch
settings = []
puts "✅ Skipped LMS settings creation due to schema issues"

puts ""
puts "=" * 50
puts "🎉 SAMPLE DATA CREATION COMPLETE!"
puts ""
puts "Summary:"
puts "- #{users.count} users created"
puts "- #{courses.count} courses created"
puts "- #{batches.count} batches created"
puts "- #{enrollments.count} course enrollments created"
puts "- #{batch_enrollments.count} batch enrollments created"
puts "- #{quizzes.count} quizzes created"
puts "- #{discussions.count} discussions created"
puts "- #{programs.count} programs created"
puts "- #{notifications.count} notifications created"
puts "- #{settings.count} LMS settings created"
puts ""
puts "You can now run the endpoint tests to validate functionality!"
puts "=" * 50
