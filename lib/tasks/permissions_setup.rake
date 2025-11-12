namespace :permissions do
  desc "Set up default permissions for the LMS"
  task setup: :environment do
    puts "Setting up default permissions..."

    Permission.create_default_permissions

    puts "Default permissions created successfully!"
  end
end
