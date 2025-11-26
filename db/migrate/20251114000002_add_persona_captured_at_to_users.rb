class AddPersonaCapturedAtToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :persona_captured_at, :datetime
    add_column :users, :persona_role, :string
    add_column :users, :persona_use_case, :string
    add_column :users, :persona_responses, :text
  end
end
