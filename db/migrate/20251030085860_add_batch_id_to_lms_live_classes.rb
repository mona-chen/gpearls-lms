class AddBatchIdToLmsLiveClasses < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_live_classes, :batch_id, :integer
  end
end
