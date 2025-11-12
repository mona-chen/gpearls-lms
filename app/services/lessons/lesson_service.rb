# frozen_string_literal: true

module Lessons
  class LessonService
    def self.get_info(lesson_id)
      lesson = ::Lesson.find_by(id: lesson_id)
      return { error: 'Lesson not found' } unless lesson

      # Get additional lesson data
      chapter = lesson.chapter
      course = lesson.course

      {
        name: lesson.id,
        title: lesson.title,
        description: lesson.description || '',
        chapter: chapter&.title,
        chapter_id: chapter&.id,
        course: course&.title,
        course_id: course&.id,
        content: lesson.content || '',
        video_url: lesson.video_url,
        duration_minutes: lesson.duration_minutes || 0,
        order: lesson.order || 0,
        is_published: lesson.is_published || false,
        created_at: lesson.created_at&.strftime('%Y-%m-%d %H:%M:%S'),
        modified_at: lesson.updated_at&.strftime('%Y-%m-%d %H:%M:%S')
      }
    rescue => e
      {
        error: 'Failed to get lesson info',
        details: e.message
      }
    end

    def self.get_creation_details(course_id, chapter_id, lesson_id)
      lesson = ::Lesson.find_by(id: lesson_id)
      return { error: 'Lesson not found' } unless lesson

      chapter = lesson.chapter
      course = lesson.course

      # Check if user has permission to create lessons
      # This would typically check if user is instructor or course creator

      {
        lesson: {
          name: lesson.id,
          title: lesson.title,
          description: lesson.description || '',
          chapter: chapter&.title,
          course: course&.title,
          content: lesson.content || '',
          video_url: lesson.video_url,
          duration_minutes: lesson.duration_minutes || 0,
          order: lesson.order || 0,
          is_published: lesson.is_published || false
        },
        chapter_info: {
          id: chapter&.id,
          title: chapter&.title,
          order: chapter&.order || 0,
          lesson_count: chapter&.lessons&.count || 0
        },
        course_info: {
          id: course&.id,
          title: course&.title,
          instructor: course&.instructor&.full_name,
          published: course&.published || false
        },
        permissions: {
          can_edit: true, # This would check actual user permissions
          can_delete: true, # This would check actual user permissions
          can_publish: true # This would check actual user permissions
        }
      }
    rescue => e
      {
        error: 'Failed to get lesson creation details',
        details: e.message
      }
    end

    def self.create_lesson(params, user)
      return { error: 'User not authenticated' } unless user
      return { error: 'Course not found' } unless params[:course_id]

      course = ::Course.find_by(id: params[:course_id])
      return { error: 'Course not found' } unless course

      # Check if user has permission to create lessons in this course
      unless course.instructor == user || user.moderator?
        return { error: 'Permission denied' }
      end

      # Find or create chapter
      chapter = if params[:chapter_id]
                  ::Chapter.find_by(id: params[:chapter_id])
                else
                  ::Chapter.create!(
                    title: params[:chapter_title] || "New Chapter",
                    course: course,
                    order: params[:chapter_order] || 1
                  )
                end

      lesson = ::Lesson.create!(
        title: params[:title],
        description: params[:description],
        chapter: chapter,
        course: course,
        content: params[:content],
        video_url: params[:video_url],
        duration_minutes: params[:duration_minutes] || 0,
        order: params[:order] || chapter.lessons.count + 1,
        is_published: params[:is_published] || false
      )

      {
        success: true,
        lesson: get_info(lesson.id),
        message: 'Lesson created successfully'
      }
    rescue => e
      {
        error: 'Failed to create lesson',
        details: e.message
      }
    end

    def self.update_lesson(lesson_id, params, user)
      lesson = ::Lesson.find_by(id: lesson_id)
      return { error: 'Lesson not found' } unless lesson
      return { error: 'User not authenticated' } unless user

      # Check permissions
      unless lesson.course.instructor == user || user.moderator?
        return { error: 'Permission denied' }
      end

      update_attrs = {}
      update_attrs[:title] = params[:title] if params[:title].present?
      update_attrs[:description] = params[:description] if params[:description].present?
      update_attrs[:content] = params[:content] if params[:content].present?
      update_attrs[:video_url] = params[:video_url] if params[:video_url].present?
      update_attrs[:duration_minutes] = params[:duration_minutes] if params[:duration_minutes].present?
      update_attrs[:is_published] = params[:is_published] if params[:is_published].present?

      lesson.update!(update_attrs)

      {
        success: true,
        lesson: get_info(lesson.id),
        message: 'Lesson updated successfully'
      }
    rescue => e
      {
        error: 'Failed to update lesson',
        details: e.message
      }
    end

    def self.delete_lesson(lesson_id, user)
      lesson = ::Lesson.find_by(id: lesson_id)
      return { error: 'Lesson not found' } unless lesson
      return { error: 'User not authenticated' } unless user

      # Check permissions
      unless lesson.course.instructor == user || user.moderator?
        return { error: 'Permission denied' }
      end

      lesson.destroy

      {
        success: true,
        message: 'Lesson deleted successfully'
      }
    rescue => e
      {
        error: 'Failed to delete lesson',
        details: e.message
      }
    end
  end
end
