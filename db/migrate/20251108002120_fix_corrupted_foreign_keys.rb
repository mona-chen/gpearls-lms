class FixCorruptedForeignKeys < ActiveRecord::Migration[7.2]
  def change
    # Remove corrupted foreign key references (only if they exist)
    begin
      remove_foreign_key "certificate_requests", "courses"
    rescue
      # Foreign key doesn't exist, skip
    end

    begin
      remove_foreign_key "certificate_requests", "evaluators"
    rescue
      # Foreign key doesn't exist, skip
    end

    # Add correct foreign key references (only if they don't exist)
    begin
      add_foreign_key "certificate_requests", "lms_courses", column: "course_id"
    rescue
      # Foreign key already exists, skip
    end

    begin
      add_foreign_key "certificate_requests", "users", column: "evaluator_id"
    rescue
      # Foreign key already exists, skip
    end
  end
end
