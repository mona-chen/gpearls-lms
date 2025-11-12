module Batches
  class MyBatchesService
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      return [] unless @user

      batch_enrollments = @user.batch_enrollments.includes(:batch, :payment)

      batch_enrollments.map do |enrollment|
        batch = enrollment.batch

        # Frappe-compatible format matching lms/utils.py get_my_batches
        {
          name: batch.id,
          title: batch.title,
          description: batch.description,
          start_date: batch.start_date&.strftime("%Y-%m-%d"),
          end_date: batch.end_date&.strftime("%Y-%m-%d"),
          published: batch.published,
          enrollment: {
            name: enrollment.id,
            batch: enrollment.batch_id,
            member: enrollment.user_id,
            enrolled_at: enrollment.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
            status: enrollment.status
          }
        }
      end
    end
  end
end
