FactoryBot.define do
  factory :workflow_transition do
    workflow { nil }
    state { "MyString" }
    action { "MyString" }
    next_state { "MyString" }
    allowed_roles { "MyString" }
    condition { "MyString" }
  end
end
