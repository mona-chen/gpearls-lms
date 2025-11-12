#!/usr/bin/env ruby

# Simple test script to verify User model works
require 'bundler/setup'
require 'rails'
require './config/application'

Rails.application.initialize!

puts "Testing User model..."

# Test basic User creation
begin
  user = User.new(
    email: 'test@example.com',
    full_name: 'Test User',
    password: 'password123',
    password_confirmation: 'password123'
  )

  if user.save
    puts "✅ User creation successful"
    puts "  - ID: #{user.id}"
    puts "  - Email: #{user.email}"
    puts "  - Full name: #{user.full_name}"
    puts "  - Username: #{user.username}"
    puts "  - Role: #{user.role}"

    # Test role methods
    puts "  - Is student?: #{user.student?}"
    puts "  - Role names: #{user.role_names.inspect}"

    # Test session_user method
    session_data = user.session_user
    puts "  - Session user keys: #{session_data.keys.inspect}"

    # Clean up
    user.destroy
    puts "✅ User cleanup successful"
  else
    puts "❌ User creation failed: #{user.errors.full_messages.join(', ')}"
  end
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end

puts "User model test completed."
