class RemoveAmountUsdFromCourses < ActiveRecord::Migration[7.2]
  def change
    remove_column :courses, :amount_usd, :decimal
  end
end
