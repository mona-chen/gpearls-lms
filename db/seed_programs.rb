# Seed script for LMS Programs
# Run with: rails runner db/seed_programs.rb

puts "Creating sample LMS Programs..."

# Create sample programs
programs_data = [
  {
    title: "Full Stack Web Development",
    description: "Complete web development program covering frontend and backend technologies",
    short_introduction: "Become a full stack developer",
    category: "Web Development",
    tags: "javascript,react,ruby,rails,postgresql",
    published: true,
    featured: true,
    owner: "admin@lms.test"
  },
  {
    title: "Data Science Fundamentals",
    description: "Learn data science from basics to advanced concepts",
    short_introduction: "Master data science skills",
    category: "Data Science",
    tags: "python,sql,machine-learning,statistics",
    published: true,
    featured: false,
    owner: "admin@lms.test"
  },
  {
    title: "Mobile App Development",
    description: "Build native mobile applications for iOS and Android",
    short_introduction: "Create mobile apps",
    category: "Mobile Development",
    tags: "react-native,flutter,swift,kotlin",
    published: false,
    featured: false,
    owner: "instructor@lms.test"
  }
]

# Create programs
programs = []
programs_data.each do |program_data|
  program = LmsProgram.new(program_data)
  # Generate name from title if not present
  program.name ||= program.title.parameterize.upcase
  program.creation = Time.current
  program.modified = Time.current

  if program.save
    programs << program
    puts "✅ Created program: #{program.title}"
  else
    puts "❌ Failed to create program: #{program.errors.full_messages.join(', ')}"
  end
end

# Enroll current user in some programs
if programs.any?
  current_user = User.find_by(email: "admin@lms.test")

  if current_user
    programs[0..1].each_with_index do |program, index|
      member = LmsProgramMember.new(
        lms_program: program,
        user: current_user,
        progress: (index + 1) * 25.0, # 25% and 50% progress
        creation: Time.current,
        modified: Time.current
      )

      if member.save
        puts "✅ Enrolled #{current_user.email} in #{program.title} with #{member.progress}% progress"
      else
        puts "❌ Failed to enroll in #{program.title}: #{member.errors.full_messages.join(', ')}"
      end
    end
  else
    puts "⚠️  User admin@lms.test not found"
  end
end

# Update program counts
programs.each do |program|
  program.update_counts
  puts "📊 Updated counts for #{program.title}: #{program.course_count} courses, #{program.member_count} members"
end

puts "✨ Sample LMS Programs created successfully!"
