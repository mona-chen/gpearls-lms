# LMS API Seeds - Development Test Data
# Run with: rails db:seed

puts "🌱 Seeding LMS API development data..."

# Create test users
puts "👤 Creating users..."
admin = User.find_or_create_by!(email: 'admin@lms.test') do |user|
  user.full_name = 'Admin User'
  user.username = 'admin'
  user.password = 'password123'
  user.is_moderator = true
  user.enabled = true
end

instructor = User.find_or_create_by!(email: 'instructor@lms.test') do |user|
  user.full_name = 'John Instructor'
  user.username = 'john_instructor'
  user.password = 'password123'
  user.is_instructor = true
  user.enabled = true
end

student = User.find_or_create_by!(email: 'student@lms.test') do |user|
  user.full_name = 'Jane Student'
  user.username = 'jane_student'
  user.password = 'password123'
  user.is_student = true
  user.enabled = true
end

puts "📚 Creating courses..."
ruby_course = Course.find_or_create_by!(title: 'Ruby Programming Fundamentals') do |course|
  course.description = 'Learn Ruby programming from basics to advanced concepts'
  course.short_introduction = 'Master Ruby programming language'
  course.published = true
  course.published_on = 1.month.ago
  course.featured = true
  course.instructor = instructor
  course.category = 'Programming'
  course.tags = 'ruby,programming,backend'
  course.course_price = 99.99
  course.currency = 'USD'
  course.enable_certification = true
  course.lessons_count = 10
  course.enrollments_count = 5
  course.rating = 4.5
end

js_course = Course.find_or_create_by!(title: 'JavaScript for Beginners') do |course|
  course.description = 'Complete JavaScript course for beginners'
  course.short_introduction = 'Start your JavaScript journey'
  course.published = true
  course.published_on = 2.weeks.ago
  course.instructor = instructor
  course.category = 'Programming'
  course.tags = 'javascript,frontend,web'
  course.course_price = 79.99
  course.currency = 'USD'
  course.enable_certification = true
  course.lessons_count = 8
  course.enrollments_count = 3
  course.rating = 4.2
end

puts "📖 Creating chapters and lessons..."
# Ruby Course Chapters
intro_chapter = Chapter.find_or_create_by!(title: 'Introduction to Ruby', course: ruby_course) do |chapter|
  chapter.position = 1
end

Lesson.find_or_create_by!(title: 'What is Ruby?', chapter: intro_chapter, course: ruby_course) do |lesson|
  lesson.body = 'Ruby is a dynamic, open-source programming language...'
  lesson.include_in_preview = true
  lesson.position = 1
end

Lesson.find_or_create_by!(title: 'Installing Ruby', chapter: intro_chapter, course: ruby_course) do |lesson|
  lesson.body = 'Learn how to install Ruby on your system...'
  lesson.include_in_preview = true
  lesson.position = 2
end

# JavaScript Course Chapters
js_intro_chapter = Chapter.find_or_create_by!(title: 'Getting Started with JavaScript', course: js_course) do |chapter|
  chapter.position = 1
end

Lesson.find_or_create_by!(title: 'JavaScript Basics', chapter: js_intro_chapter, course: js_course) do |lesson|
  lesson.body = 'JavaScript is a programming language...'
  lesson.include_in_preview = true
  lesson.position = 1
end

puts "🎓 Creating enrollments..."
Enrollment.find_or_create_by!(user: student, course: ruby_course) do |enrollment|
  enrollment.progress = 30.0
  enrollment.current_lesson = '1-1'
  enrollment.member_type = 'Student'
end

Enrollment.find_or_create_by!(user: student, course: js_course) do |enrollment|
  enrollment.progress = 0.0
  enrollment.member_type = 'Student'
end

puts "📝 Creating quizzes..."
ruby_quiz = Quiz.find_or_create_by!(title: 'Ruby Basics Quiz', course: ruby_course) do |quiz|
  quiz.description = 'Test your knowledge of Ruby fundamentals'
  quiz.passing_percentage = 70
  quiz.total_marks = 10
end

# Quiz Questions
QuizQuestion.find_or_create_by!(question: 'What is Ruby?', quiz: ruby_quiz) do |question|
  question.type = 'Choices'
  question.multiple = false
  question.option_1 = 'A programming language'
  question.option_2 = 'A gemstone'
  question.option_3 = 'A coffee type'
  question.option_4 = 'A car brand'
  question.explanation_1 = 'Correct! Ruby is a programming language.'
  question.marks = 2
  question.position = 1
end

puts "🏆 Creating certificates..."
Certificate.find_or_create_by!(user: student, course: ruby_course) do |certificate|
  certificate.issue_date = 1.week.ago
  certificate.expiry_date = 1.year.from_now
  certificate.template = 'default'
  certificate.published = true
end

puts "⚙️ Creating settings..."
Setting.find_or_create_by!(key: 'allow_guest_access') do |setting|
  setting.value = '1'
end

Setting.find_or_create_by!(key: 'default_currency') do |setting|
  setting.value = 'USD'
end

puts "✅ LMS API seeding completed!"
puts ""
puts "🔐 Test Accounts:"
puts "   Admin: admin@lms.test / password123"
puts "   Instructor: instructor@lms.test / password123"
puts "   Student: student@lms.test / password123"
puts ""
puts "🚀 Start server with: rails server"
puts "🧪 Test login with: curl -X POST http://localhost:3000/api/login -d 'usr=student@lms.test&pwd=password123'"
