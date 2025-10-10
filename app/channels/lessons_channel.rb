class LessonsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "lesson_#{params[:lesson_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def update_progress(data)
    lesson = Lesson.find_by(id: params[:lesson_id])
    if lesson
      progress = LessonProgress.find_or_initialize_by(
        user: current_user,
        lesson: lesson
      )

      progress.update(
        progress: data['progress'],
        completed: data['completed'] || false,
        last_accessed_at: Time.current
      )

      # Broadcast progress update to other users in the lesson
      ActionCable.server.broadcast(
        "lesson_#{params[:lesson_id]}",
        type: 'lesson_progress_updated',
        user_id: current_user.id,
        progress: progress.progress,
        completed: progress.completed,
        lesson_id: lesson.id
      )
    end
  end
end