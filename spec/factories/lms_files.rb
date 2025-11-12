FactoryBot.define do
  factory :lms_file do
    file_name { Faker::File.file_name }
    file_url { "/uploads/files/#{file_name}" }
    file_type { 'application/pdf' }
    file_size { 1024 }
    is_private { false }
    uploaded_by { create(:user) }
  end
end
