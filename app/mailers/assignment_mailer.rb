class AssignmentMailer < ApplicationMailer
  def assignment_submission_notification(assignment_submission)
    @instructor_name = assignment_submission.assignment.course.instructors.first&.full_name || 'Instructor'
    @course_title = assignment_submission.assignment.course.title
    @assignment_title = assignment_submission.assignment.title
    @student_name = assignment_submission.user.full_name || assignment_submission.user.email
    @submission_date = assignment_submission.created_at
    @assignment_url = Rails.application.routes.url_helpers.assignment_url(assignment_submission.assignment)
    
    # Send to all course instructors
    instructors = assignment_submission.assignment.course.instructors
    instructors.each do |instructor|
      mail(
        to: instructor.email,
        subject: "New Assignment Submission - #{@assignment_title}"
      )
    end
  end
  
  def assignment_graded(assignment_submission)
    @student_name = assignment_submission.user.full_name || assignment_submission.user.email
    @course_title = assignment_submission.assignment.course.title
    @assignment_title = assignment_submission.assignment.title
    @grade = assignment_submission.grade
    @feedback = assignment_submission.feedback
    @assignment_url = Rails.application.routes.url_helpers.assignment_url(assignment_submission.assignment)
    
    mail(
      to: assignment_submission.user.email,
      subject: "Assignment Graded - #{@assignment_title}"
    )
  end
  
  def assignment_due_reminder(assignment, user)
    @student_name = user.full_name || user.email
    @course_title = assignment.course.title
    @assignment_title = assignment.title
    @due_date = assignment.due_date
    @assignment_url = Rails.application.routes.url_helpers.assignment_url(assignment)
    
    mail(
      to: user.email,
      subject: "Assignment Due Soon - #{@assignment_title}"
    )
  end
end