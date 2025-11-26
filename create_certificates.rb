# Create some sample certificates with real data
users = User.limit(3)
courses = Course.limit(3)

categories = [ 'Programming', 'Web Development', 'Data Science', 'Mobile Development', 'UI/UX Design' ]

users.each_with_index do |user, index|
  course = courses[index % courses.length]
  Certificate.create!(
    user: user,
    course: course,
    name: "#{course.title} Certificate",
    category: categories[index % categories.length],
    issue_date: Date.today - index.days,
    expiry_date: Date.today + 365.days,
    published: true
  )
end

puts 'Created sample certificates'
