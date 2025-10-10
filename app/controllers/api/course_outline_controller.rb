class Api::CourseOutlineController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    course = Course.find(params[:course])
    return render json: { error: 'Course not found' }, status: :not_found unless course

    # Check permissions
    unless course.published || (current_user && (current_user.moderator? || course.instructor == current_user))
      return render json: { error: 'Unauthorized' }, status: :forbidden
    end

    outline = course.chapters.order(:idx).map do |chapter|
      {
        name: chapter.id,
        title: chapter.title,
        idx: chapter.idx,
        is_scorm_package: chapter.is_scorm_package,
        launch_file: chapter.launch_file,
        scorm_package: chapter.scorm_package ? { name: chapter.scorm_package } : nil,
        lessons: chapter.lessons.order(:idx).map do |lesson|
          {
            name: lesson.id,
            title: lesson.title,
            idx: lesson.idx,
            include_in_preview: lesson.include_in_preview,
            is_scorm_package: lesson.is_scorm_package
          }
        end
      }
    end

    render json: outline
  end
end