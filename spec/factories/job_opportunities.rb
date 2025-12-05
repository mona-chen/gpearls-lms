FactoryBot.define do
  factory :job_opportunity do
    job_title { "MyString" }
    location { "MyString" }
    country { "MyString" }
    type { "" }
    work_mode { "MyString" }
    company_name { "MyString" }
    company_logo { "MyString" }
    company_website { "MyString" }
    company_email_address { "jobs@company.com" }
    description { "MyText" }
     published { false }
  end
end
