class AddInstructorIdToBatches < ActiveRecord::Migration[7.2]
  def change
    add_reference :batches, :instructor, null: true, foreign_key: { to_table: :users }
  end
end
