class BatchCourse < ApplicationRecord
  belongs_to :batch
  belongs_to :course
  belongs_to :evaluator, class_name: 'User', optional: true
end