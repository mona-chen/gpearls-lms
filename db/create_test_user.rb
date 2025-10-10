User.create!(
  email: 'test@example.com',
  password: 'password',
  password_confirmation: 'password',
  full_name: 'Test User',
  username: 'testuser',
  user_type: 'LMS Student'
)

puts "Test user created: test@example.com / password"