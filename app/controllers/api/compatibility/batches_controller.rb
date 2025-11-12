module Api
  module Compatibility
    class BatchesController < BaseController
      def get_my_batches
        return render json: { data: [] } unless current_user

        batches = Batches::MyBatchesService.call(current_user)
        render json: { data: batches }
      end

      def get_batches
        batches = Batch.includes(:instructor, :course)

        # Apply filters
        batches = apply_filters(batches)

        # Apply ordering
        if params[:order_by].present?
          batches = batches.order(params[:order_by])
        else
          batches = batches.order(start_date: :desc)
        end

        # Apply pagination
        limit = params[:limit] || 20
        offset = params[:start] || 0
        batches = batches.limit(limit).offset(offset)

        batches_data = batches.map { |batch| format_batch(batch) }
        render json: { data: batches_data }
      end

      def get_upcoming_evals
        return render json: { data: [] } unless current_user

        user_courses = current_user.enrollments.pluck(:course_id)
        quizzes = Quiz.where(course_id: user_courses)
                      .order(:created_at)
                      .limit(10)

        evals_data = quizzes.map do |quiz|
          {
            course: quiz.course.title,
            course_id: quiz.course.id,
            quiz: quiz.title,
            quiz_id: quiz.id,
            scheduled_date: quiz.scheduled_date || Date.today.strftime('%Y-%m-%d'),
            duration: quiz.duration || 30,
            max_attempts: quiz.max_attempts || 3,
            passing_percentage: quiz.passing_percentage || 70,
            questions_count: quiz.quiz_questions&.count || 0
          }
        end

        render json: { data: evals_data }
      end

      private

      def apply_filters(batches)
        return batches unless params[:filters].present?

        filters = params[:filters].to_unsafe_h
        if filters['start_date']
          start_date = filters['start_date'].first == ">=" ? Date.today : filters['start_date'].first
          batches = batches.where("start_date >= ?", start_date)
        end
        batches = batches.where(published: true) if filters['published'] == 1
        batches
      end

      def format_batch(batch)
        {
          name: batch.name,
          title: batch.name,
          batch_id: batch.id,
          course_id: batch.course&.id,
          course_title: batch.course&.title,
          start_date: batch.start_date&.strftime('%Y-%m-%d'),
          end_date: batch.end_date&.strftime('%Y-%m-%d'),
          instructor: batch.instructor&.full_name,
          description: batch.description,
          max_students: batch.max_students,
          current_students: batch.batch_enrollments.count,
          published: batch.published,
          creation: batch.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          modified: batch.updated_at.strftime('%Y-%m-%d %H:%M:%S'),
          owner: batch.instructor&.email
        }
      end
    end
  end
end