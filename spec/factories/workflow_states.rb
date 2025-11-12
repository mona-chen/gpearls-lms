FactoryBot.define do
  factory :workflow_state do
    workflow { nil }
    state { "MyString" }
    doc_status { "MyString" }
    allow_edit { "MyString" }
    next_action { "MyString" }
  end
end
