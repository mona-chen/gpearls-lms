namespace :workflow do
  desc "Set up default workflows for the LMS"
  task setup: :environment do
    puts "Setting up default course approval workflow..."

    Workflows::WorkflowsService.create_default_course_workflow

    puts "Default workflow created successfully!"
  end
end
