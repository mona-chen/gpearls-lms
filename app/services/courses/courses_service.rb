module Courses
  class CoursesService
    def self.call(params = {})
      new(params).call
    end

    def initialize(params = {})
      @params = params
    end

    def call
      courses = base_course_query

      # Apply filters
      courses = apply_filters(courses)

      # Apply pagination
      courses = apply_pagination(courses)

      # Format response to match Frappe API expectations
      courses_data = courses.map do |course|
        format_course_for_listing(course)
      end

      { "data" => courses_data }
    end

    private

    def base_course_query
      Course.includes(:instructor, :enrollments)
            .published
            .order(featured: :desc, created_at: :desc)
    end

    def apply_filters(courses)
      return courses unless @params[:filters].present?

      filters = normalize_filters(@params[:filters])

      courses = courses.where(published: true) if filters["published"] == 1 || filters[:published] == 1
      courses = courses.where(upcoming: [ false, nil ]) if filters["upcoming"] == 0 || filters[:upcoming] == 0
      courses = courses.where(featured: true) if filters["featured"] == 1 || filters[:featured] == 1
      courses = courses.where(category: filters["category"] || filters[:category]) if filters["category"].present? || filters[:category].present?
      courses = courses.where("title LIKE ?", "%#{filters['search'] || filters[:search]}%") if filters["search"].present? || filters[:search].present?

      courses
    end

    def apply_pagination(courses)
      limit = (@params[:limit] || 20).to_i.clamp(1, 100)
      offset = (@params[:start] || 0).to_i

      courses.limit(limit).offset(offset)
    end

    def normalize_filters(filters)
      if filters.respond_to?(:to_h)
        filters.to_h
      else
        filters
      end
    end

    def format_course_for_listing(course)
      {
        "name" => course.id,
        "title" => course.title,
        "description" => course.description,
        "tags" => course.tags&.split(",") || [],
        "image" => course.image,
        "card_gradient" => course.card_gradient,
        "short_introduction" => course.short_introduction,
        "video_link" => course.video_link,
        "published" => course.published,
        "upcoming" => course.upcoming?,
        "featured" => course.featured,
        "published_on" => course.published_at&.strftime("%Y-%m-%d %H:%M:%S"),
        "category" => course.category,
        "status" => course.published? ? "Published" : "Draft",
        "course_price" => course.price,
        "currency" => course.currency,
        "lessons" => course.total_lessons,
        "enrollments" => course.enrollment_count,
        "enrollment_count" => course.enrollment_count,
        "rating" => calculate_course_rating(course),
        "creation" => course.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
        "modified" => course.updated_at&.strftime("%Y-%m-%d %H:%M:%S"),
        "owner" => course.instructor&.email,
        "instructor" => course.instructor&.full_name,
        "instructor_id" => course.instructor&.id
      }
    end

    # NEW: Get courses created by a specific user
    def self.get_created_courses(user)
      return { error: "User not authenticated" } unless user

      courses = Course.where(instructor: user)
                     .includes(:instructor, :chapters, :lessons)
                     .order(created_at: :desc)

      courses_data = courses.map do |course|
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
          status: course.published ? "Approved" : "Under Review",
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
          created_at: course.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          modified_at: course.updated_at.strftime("%Y-%m-%d %H:%M:%S")
        }
      end

      {
        success: true,
        courses: courses_data,
        total: courses_data.count,
        message: "Retrieved #{courses_data.count} courses created by #{user.full_name}"
      }
    end

    # NEW: Create a new course
    def self.create_course(params, user)
      return { error: "User not authenticated" } unless user
      return { error: "Title is required" } unless params[:title].present?
      return { error: "Short introduction is required" } unless params[:short_introduction].present?

      # Check if user has permission to create courses
      unless user.instructor? || user.moderator?
        return { error: "Permission denied. Only instructors and moderators can create courses." }
      end

      begin
        course = Course.create!(
          title: params[:title],
          description: params[:description],
          short_introduction: params[:short_introduction],
          video_link: params[:video_link],
          image: params[:image],
          card_gradient: params[:card_gradient],
          tags: params[:tags]&.join(","),
          category: params[:category],
          published: params[:published] || false,
          upcoming: params[:upcoming] || false,
          featured: params[:featured] || false,
          disable_self_learning: params[:disable_self_learning] || false,
          course_price: params[:course_price],
          currency: params[:currency] || "NGN",
          paid_course: params[:paid_course] || false,
          enable_certification: params[:enable_certification] || false,
          paid_certificate: params[:paid_certificate] || false,
          instructor: user
        )

        {
          success: true,
          course: course.to_frappe_format,
          message: "Course created successfully"
        }
      rescue => e
        {
          error: "Failed to create course",
          details: e.message
        }
      end
    end

    def calculate_course_rating(course)
      # TODO: Implement real rating calculation from reviews table when available
      # For now, return a reasonable default based on enrollment completion
      return 0 if course.enrollments.empty?

      total_progress = course.enrollments.sum(:progress_percentage)
      average_completion = total_progress.to_f / course.enrollments.count
      base_rating = (average_completion / 100 * 5).round(1)
      [ base_rating, 5.0 ].min
    end

    # Advanced course management methods
    def self.reindex_exercises(course_id, user)
      return { error: "User not authenticated" } unless user
      return { error: "Permission denied" } unless user.instructor? || user.moderator?

      course = Course.find_by(id: course_id)
      return { error: "Course not found" } unless course

      # Reindex all exercises in the course
      exercises = LmsExercise.where(course_id: course_id).order(:creation)
      exercises.each_with_index do |exercise, index|
        exercise.update!(idx: index + 1)
      end

      { success: true, message: "Exercises reindexed successfully", total_exercises: exercises.count }
    rescue => e
      { error: "Failed to reindex exercises: #{e.message}" }
    end

    def self.get_lesson_creation_details(course_id, user)
      return { error: "User not authenticated" } unless user
      return { error: "Permission denied" } unless user.instructor? || user.moderator?

      course = Course.find_by(id: course_id)
      return { error: "Course not found" } unless course

      chapters = course.chapters.order(:index)
      chapter_details = chapters.map do |chapter|
        {
          name: chapter.id,
          title: chapter.title,
          description: chapter.description,
          index: chapter.index,
          lessons_count: chapter.lessons.count,
          lessons: chapter.lessons.order(:index).map do |lesson|
            {
              name: lesson.id,
              title: lesson.title,
              content: lesson.content,
              index: lesson.index,
              include_in_preview: lesson.include_in_preview,
              body: lesson.body
            }
          end
        }
      end

      {
        success: true,
        course: {
          name: course.id,
          title: course.title,
          chapters: chapter_details
        }
      }
    rescue => e
      { error: "Failed to get lesson creation details: #{e.message}" }
    end

    def self.autosave_section(course_id, chapter_id, lesson_id, content, user)
      return { error: "User not authenticated" } unless user
      return { error: "Permission denied" } unless user.instructor? || user.moderator?

      course = Course.find_by(id: course_id)
      return { error: "Course not found" } unless course

      if lesson_id.present?
        lesson = Lesson.find_by(id: lesson_id, chapter_id: chapter_id)
        return { error: "Lesson not found" } unless lesson

        lesson.update!(body: content, updated_at: Time.current)
        { success: true, message: "Lesson content autosaved", lesson_id: lesson.id }
      elsif chapter_id.present?
        chapter = Chapter.find_by(id: chapter_id, course_id: course_id)
        return { error: "Chapter not found" } unless chapter

        chapter.update!(description: content, updated_at: Time.current)
        { success: true, message: "Chapter description autosaved", chapter_id: chapter.id }
      else
        { error: "Either chapter_id or lesson_id must be provided" }
      end
    rescue => e
      { error: "Failed to autosave section: #{e.message}" }
    end

    def self.update_chapter_index(course_id, chapter_id, new_index, user)
      return { error: "User not authenticated" } unless user
      return { error: "Permission denied" } unless user.instructor? || user.moderator?

      course = Course.find_by(id: course_id)
      return { error: "Course not found" } unless course

      chapter = Chapter.find_by(id: chapter_id, course_id: course_id)
      return { error: "Chapter not found" } unless chapter

      # Update chapter index and reindex other chapters
      Chapter.transaction do
        # Shift other chapters
        if new_index > chapter.index
          course.chapters.where("index > ? AND index <= ?", chapter.index, new_index)
                .update_all("index = index - 1")
        else
          course.chapters.where("index >= ? AND index < ?", new_index, chapter.index)
                .update_all("index = index + 1")
        end

        chapter.update!(index: new_index)
      end

      { success: true, message: "Chapter index updated successfully" }
    rescue => e
      { error: "Failed to update chapter index: #{e.message}" }
    end

    def self.update_lesson_index(course_id, chapter_id, lesson_id, new_index, user)
      return { error: "User not authenticated" } unless user
      return { error: "Permission denied" } unless user.instructor? || user.moderator?

      chapter = Chapter.find_by(id: chapter_id, course_id: course_id)
      return { error: "Chapter not found" } unless chapter

      lesson = Lesson.find_by(id: lesson_id, chapter_id: chapter_id)
      return { error: "Lesson not found" } unless lesson

      # Update lesson index and reindex other lessons in the chapter
      Lesson.transaction do
        # Shift other lessons in the same chapter
        if new_index > lesson.index
          chapter.lessons.where("index > ? AND index <= ?", lesson.index, new_index)
                  .update_all("index = index - 1")
        else
          chapter.lessons.where("index >= ? AND index < ?", new_index, lesson.index)
                  .update_all("index = index + 1")
        end

        lesson.update!(index: new_index)
      end

      { success: true, message: "Lesson index updated successfully" }
    rescue => e
      { error: "Failed to update lesson index: #{e.message}" }
    end

    def self.upsert_chapter(course_id, chapter_data, user)
      return { error: "User not authenticated" } unless user
      return { error: "Permission denied" } unless user.instructor? || user.moderator?

      course = Course.find_by(id: course_id)
      return { error: "Course not found" } unless course

      chapter_id = chapter_data[:chapter_id] || chapter_data[:name]

      if chapter_id.present?
        # Update existing chapter
        chapter = Chapter.find_by(id: chapter_id, course_id: course_id)
        return { error: "Chapter not found" } unless chapter

        chapter.update!(
          title: chapter_data[:title],
          description: chapter_data[:description],
          index: chapter_data[:index] || chapter.index
        )

        { success: true, message: "Chapter updated successfully", chapter: chapter }
      else
        # Create new chapter
        max_index = course.chapters.maximum(:index) || 0
        chapter = Chapter.create!(
          course: course,
          title: chapter_data[:title],
          description: chapter_data[:description],
          index: chapter_data[:index] || (max_index + 1)
        )

        { success: true, message: "Chapter created successfully", chapter: chapter }
      end
    rescue => e
      { error: "Failed to upsert chapter: #{e.message}" }
    end

    def self.get_course_details(course_id)
      course_id = course_id[:course] || course_id[:id] if course_id.is_a?(Hash)
      course = Course.find_by(id: course_id)

      unless course
        return { "error" => "Course not found", "status" => 404 }
      end

      {
        "name" => course.id,
        "title" => course.title,
        "description" => course.description,
        "short_introduction" => course.short_introduction,
        "published" => course.published,
        "upcoming" => course.upcoming?,
        "featured" => course.featured,
        "disable_self_learning" => course.disable_self_learning,
        "course_price" => course.course_price,
        "currency" => course.currency,
        "amount_usd" => course.amount_usd,
        "paid_course" => course.paid_course,
        "enable_certification" => course.enable_certification,
        "paid_certificate" => course.paid_certificate,
        "evaluator" => course.evaluator&.name,
        "video_link" => course.video_link,
        "tags" => course.tags,
        "image" => course.image,
        "card_gradient" => course.card_gradient,
        "instructors" => course.instructors,
        "category" => course.category&.name,
        "enrollments" => course.enrollment_count,
        "lessons" => course.total_lessons,
        "rating" => calculate_course_rating(course),
        "creation" => course.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
        "modified" => course.updated_at&.strftime("%Y-%m-%d %H:%M:%S")
      }
    end

    private
  end
end
