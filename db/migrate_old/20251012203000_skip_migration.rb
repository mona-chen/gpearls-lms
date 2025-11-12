# This migration is used to skip the CreateLmsQuizzes migration
# We need to insert a record into schema_migrations with the correct version
# SQLite doesn't allow NULL for the version field, so we need to handle this properly

class SkipMigration < ActiveRecord::Migration[7.0]
  def up
    # This migration is used to skip the CreateLmsQuizzes migration
    # We need to insert a record into schema_migrations with the correct version
    # SQLite doesn't allow NULL for the version field, so we need to handle this properly

    begin
      sql = <<~SQL
        INSERT INTO schema_migrations (version, name)
        VALUES ('20251012203000', 'CreateLmsQuizzes')
      SQL

      ActiveRecord::Base.connection.execute(sql)
    rescue ActiveRecord::StatementInvalid => e
      # If the migration already exists, we can ignore the error
      unless e.message.include?('unique constraint')
        Rails.logger.warn "Failed to skip CreateLmsQuizzes migration: #{e.message}"
      end
    end
  end

  def down
    # Remove the migration record if needed
    ActiveRecord::Base.connection.execute("DELETE FROM schema_migrations WHERE version = '20251012203000'")
  end
end
