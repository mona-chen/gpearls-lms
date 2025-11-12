class AddStatusToJobOpportunities < ActiveRecord::Migration[7.2]
  def change
    add_column :job_opportunities, :status, :string, default: 'Open'
  end
end
