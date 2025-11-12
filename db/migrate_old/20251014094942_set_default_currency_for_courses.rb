class SetDefaultCurrencyForCourses < ActiveRecord::Migration[7.2]
  def up
    Course.where(currency: [ nil, '' ]).update_all(currency: 'NGN')
  end

  def down
    # No need to reverse this migration
  end
end
