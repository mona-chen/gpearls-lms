class Api::LessonsController < Api::BaseController
  def show
    course = Course.find(params[:course])
    chapter = CourseChapter.find_by(course: course, idx: params[:chapter])
    lesson = CourseLesson.find_by(chapter: chapter, idx: params[:lesson])

    return render json: { error: "Lesson not found" }, status: :not_found unless lesson

    # Check permissions
    enrollment = current_user&.enrollments&.find_by(course: course)
    unless lesson.include_in_preview || enrollment || can_access_course?(course)
      return render json: { no_preview: 1, title: lesson.title }, status: :forbidden
    end

    progress = current_user ? CourseProgress.find_by(user: current_user, lesson: lesson)&.status == "Complete" : false

    render json: {
      name: lesson.id,
      title: lesson.title,
      include_in_preview: lesson.include_in_preview,
      body: lesson.body,
      content: lesson.content,
      instructor_notes: lesson.instructor_notes,
      instructor_content: lesson.instructor_content,
      youtube: lesson.youtube,
      quiz_id: lesson.quiz_id,
      question: lesson.question,
      file_type: lesson.file_type,
      course: lesson.course_id,
      creation: lesson.created_at,
      chapter_title: chapter.title,
      next: get_next_lesson(course, params[:chapter], params[:lesson]),
      prev: get_prev_lesson(course, params[:chapter], params[:lesson]),
      progress: progress,
      membership: enrollment&.as_json,
      icon: get_lesson_icon(lesson),
      instructors: course.instructor ? [ format_instructor(course.instructor) ] : [],
      course_title: course.title,
      paid_certificate: course.paid_certificate,
      disable_self_learning: course.disable_self_learning,
      videos: [] # TODO: Implement video tracking
    }
  end

  def update_progress
    course = Course.find(params[:course])
    chapter = CourseChapter.find_by(course: course, idx: params[:chapter])
    lesson = CourseLesson.find_by(chapter: chapter, idx: params[:lesson])

    return render json: { error: "Lesson not found" }, status: :not_found unless lesson

    progress = CourseProgress.find_or_initialize_by(user: current_user, lesson: lesson)
    progress.status = "Complete"
    progress.save

    # Update enrollment progress
    enrollment = current_user.enrollments.find_by(course: course)
    if enrollment
      total_lessons = course.lessons.count
      completed_lessons = current_user.course_progresses.joins(:lesson).where(lesson: { course: course }, status: "Complete").count
      progress_percentage = total_lessons > 0 ? (completed_lessons.to_f / total_lessons * 100).round(2) : 0
      enrollment.update(progress: progress_percentage)
    end

    render json: { success: true, progress: enrollment&.progress || 0 }
  end

  private

  def can_access_course?(course)
    current_user && (current_user.moderator? || course.instructor == current_user)
  end

  def get_next_lesson(course, chapter_num, lesson_num)
    # Simple implementation - get next lesson in sequence
    chapters = course.chapters.order(:idx)
    current_chapter = chapters.find_by(idx: chapter_num.to_i)

    if current_chapter
      lessons = current_chapter.lessons.order(:idx)
      current_lesson = lessons.find_by(idx: lesson_num.to_i)

      if current_lesson
        next_lesson = lessons.where("idx > ?", lesson_num.to_i).first
        if next_lesson
          return "#{chapter_num}-#{next_lesson.idx}"
        else
          # Next chapter
          next_chapter = chapters.where("idx > ?", chapter_num.to_i).first
          if next_chapter
            first_lesson = next_chapter.lessons.order(:idx).first
            return "#{next_chapter.idx}-#{first_lesson.idx}" if first_lesson
          end
        end
      end
    end
    nil
  end

  def get_prev_lesson(course, chapter_num, lesson_num)
    # Simple implementation - get previous lesson in sequence
    chapters = course.chapters.order(:idx)
    current_chapter = chapters.find_by(idx: chapter_num.to_i)

    if current_chapter
      lessons = current_chapter.lessons.order(:idx)
      current_lesson = lessons.find_by(idx: lesson_num.to_i)

      if current_lesson
        prev_lesson = lessons.where("idx < ?", lesson_num.to_i).last
        if prev_lesson
          return "#{chapter_num}-#{prev_lesson.idx}"
        else
          # Previous chapter
          prev_chapter = chapters.where("idx < ?", chapter_num.to_i).last
          if prev_chapter
            last_lesson = prev_chapter.lessons.order(:idx).last
            return "#{prev_chapter.idx}-#{last_lesson.idx}" if last_lesson
          end
        end
      end
    end
    nil
  end

  def get_lesson_icon(lesson)
    if lesson.content.present?
      content = JSON.parse(lesson.content) rescue []
      content.each do |block|
        if block["type"] == "upload" && block["data"]["file_type"]&.downcase&.match?(/\A(mp4|webm|ogg|mov)\z/)
          return "icon-youtube"
        elsif block["type"] == "embed" && [ "youtube", "vimeo", "cloudflareStream", "bunnyStream" ].include?(block["data"]["service"])
          return "icon-youtube"
        elsif block["type"] == "quiz"
          return "icon-quiz"
        end
      end
    end

    # Check body for macros
    if lesson.body&.include?("YouTubeVideo") || lesson.body&.include?("Video")
      return "icon-youtube"
    elsif lesson.body&.include?("Quiz")
      return "icon-quiz"
    end

    "icon-list"
  end

  def format_instructor(user)
    {
      name: user.id,
      username: user.username,
      full_name: user.full_name,
      user_image: user.user_image,
      first_name: user.first_name
    }
  end
end
