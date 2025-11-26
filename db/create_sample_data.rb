# Create sample data for testing

# Load Rails environment
require_relative '../config/environment'

# Create a sample course
instructor_user = User.find_by(email: 'test@example.com')
course = Course.create!(
  title: "Ruby Programming Fundamentals",
  description: "Learn the fundamentals of Ruby programming",
  short_introduction: "A comprehensive introduction to Ruby",
  tags: "ruby,programming,beginner",
  category: "Programming",
  published: true,
  featured: true,
  paid_course: false,
  enable_certification: true
)

# Set instructor manually to avoid association issues during creation
course.update!(instructor: instructor_user)

puts "Created course: #{course.title}"

# Create sample chapters and lessons (simplified for now)
chapter1 = Chapter.new(
  title: "Introduction to Ruby",
  position: 1
)
chapter1.course = course
chapter1.save!

lesson1 = Lesson.new(
  title: "Getting Started with Ruby",
  position: 1,
  content: "This is the first lesson about Ruby..."
)
lesson1.chapter = chapter1
lesson1.course = course
lesson1.save!

# Create enrollment for the test user
enrollment = Enrollment.create!(
  user: User.find_by(email: 'test@example.com'),
  course: course,
  progress: 25
)

puts "Created enrollment for user"

# Create sample lesson progress
progress1 = LessonProgress.create!(
  user: User.find_by(email: 'test@example.com'),
  lesson: lesson1,
  progress: 100,
  completed: true,
  last_accessed_at: Date.today
)

puts "Created lesson progress records"

# Create sample notifications
Notification.create!(
  user: User.find_by(email: 'test@example.com'),
  subject: "Welcome to Ruby Programming Fundamentals!",
  email_content: "Welcome to the course! We're excited to have you join us.",
  type: "welcome",
  read: false
)

Notification.create!(
  user: User.find_by(email: 'test@example.com'),
  subject: "New lesson available!",
  email_content: "A new lesson has been posted for your course.",
  type: "lesson",
  read: false
)

puts "Created sample notifications"

puts "\nSample data creation completed!"
puts "Course ID: #{course.id}"
puts "Lesson ID: #{lesson1.id}"
