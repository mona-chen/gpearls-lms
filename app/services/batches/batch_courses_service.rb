module Batches
  class BatchCoursesService
    def self.call(batch_name)
      new(batch_name).call
    end

    def initialize(batch_name)
      @batch_name = batch_name
    end

    def call
      batch = Batch.find_by(title: @batch_name) || Batch.find_by(id: @batch_name)
      return { error: "Batch not found" } unless batch

      courses_data = batch.batch_courses.includes(:course).map do |batch_course|
        course = batch_course.course
        next unless course # Skip if course is missing

        {
          name: course.id,
          title: course.title,
          description: course.description,
          short_introduction: course.short_introduction,
          video_link: course.video_link,
          image: course.image,
          card_gradient: course.card_gradient,
          tags: course.tags&.split(",") || [],
          category: course.category,
          status: course.published ? "Published" : "Draft",
          published: course.published,
          upcoming: course.upcoming?,
          featured: course.featured,
          disable_self_learning: course.disable_self_learning,
          course_price: course.course_price,
          currency: course.currency,
          amount_usd: course.amount_usd,
          paid_course: course.paid_course,
          enable_certification: course.enable_certification,
          paid_certificate: course.paid_certificate,
          evaluator: course.evaluator&.name,
          instructor: course.instructor&.full_name,
          chapters: course.chapters&.count || 0,
          lessons: course.lessons&.count || 0,
          enrollments: course.enrollments&.count || 0,
          rating: course.rating || 0,
          creation: course.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          modified: course.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
          # Batch-specific fields
          batch_course_id: batch_course.id,
          position: batch_course.position,
          mandatory: batch_course.mandatory
        }
      end.compact # Remove nil entries

      {
        success: true,
        courses: courses_data,
        total: courses_data.count,
        batch_name: batch.name,
        batch_title: batch.title,
        message: "Retrieved #{courses_data.count} courses for batch #{batch.title}"
      }
    end
  end
end
