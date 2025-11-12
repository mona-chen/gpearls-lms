class AddResolutionFieldsToJobReports < ActiveRecord::Migration[7.2]
  def change
    add_column :job_reports, :resolution_action, :string
  end
end
