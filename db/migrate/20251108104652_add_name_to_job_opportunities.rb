class AddNameToJobOpportunities < ActiveRecord::Migration[7.2]
  def change
    add_column :job_opportunities, :name, :string
    add_index :job_opportunities, :name, unique: true
  end
end
