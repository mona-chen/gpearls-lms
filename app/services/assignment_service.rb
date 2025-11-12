class AssignmentService
  def self.get_details(assignment_name)
    assignment = LmsAssignment.find_by(name: assignment_name)
    return { error: "Assignment not found" } unless assignment

    {
      success: true,
      assignment: assignment.to_frappe_format
    }
  rescue => e
    {
      error: "Failed to get assignment details",
      details: e.message
    }
  end

  def self.save(params, user)
    return { error: "User not authenticated" } unless user

    assignment = LmsAssignment.find_by(name: params[:assignment])
    return { error: "Assignment not found" } unless assignment

    # Create or update submission
    submission = LmsAssignmentSubmission.find_or_initialize_by(
      assignment: assignment,
      student_id: user.id
    )

    submission.submission_text = params[:answer]
    submission.status = "Submitted"
    submission.submitted_at = Time.current

    if submission.save
      {
        success: true,
        message: "Assignment submitted successfully",
        submission: submission
      }
    else
      {
        error: "Failed to submit assignment",
        details: submission.errors.full_messages
      }
    end
  rescue => e
    {
      error: "Failed to save assignment",
      details: e.message
    }
  end

  def self.upload(params, user)
    begin
      assignment_name = params[:assignment]
      file = params[:file]

      return { success: false, message: "Assignment name required" } unless assignment_name
      return { success: false, message: "File required" } unless file

      assignment = LmsAssignment.find_by(title: assignment_name) || LmsAssignment.find_by(id: assignment_name)
      return { success: false, message: "Assignment not found" } unless assignment

      # Check if user has permission to submit to this assignment
      enrollment = user.enrollments.find_by(course: assignment.course)
      return { success: false, message: "Not enrolled in course" } unless enrollment

      # Check if assignment allows file uploads
      return { success: false, message: "File uploads not allowed for this assignment" } unless assignment.allow_file_upload?

      # Check file size limit
      if file.size > LmsFile.max_file_size
        return { success: false, message: "File size exceeds maximum allowed size of #{LmsFile.max_file_size / 1.megabyte}MB" }
      end

      # Check file type
      allowed_types = LmsFile.allowed_file_types
      unless allowed_types.empty? || allowed_types.include?(file.content_type) || allowed_types.include?(File.extname(file.original_filename).downcase)
        return { success: false, message: "File type not allowed. Allowed types: #{allowed_types.join(', ')}" }
      end

      # Upload file using FileUploadService
      upload_result = System::FileUploadService.process_upload(file, user)

      if upload_result[:success]
        # Create LmsFile record
        lms_file = LmsFile.create!(
          file_name: upload_result[:file_name],
          file_url: upload_result[:file_url],
          file_type: upload_result[:file_type],
          file_size: upload_result[:file_size],
          uploaded_by: user,
          attached_to_doctype: "LMS Assignment Submission",
          attached_to_name: "#{assignment.id}_#{user.id}",
          is_private: true # Assignment submissions should be private
        )

        # Create or update assignment submission
        submission = AssignmentSubmission.find_or_initialize_by(
          user: user,
          assignment: assignment
        )

        # Store file information in submission_files JSON field
        current_files = submission.submission_files || []
        current_files << lms_file.to_frappe_format
        submission.submission_files = current_files
        submission.status = :submitted
        submission.submitted_at = Time.current
        submission.save!

        {
          success: true,
          message: "File uploaded successfully",
          data: {
            file_id: lms_file.id,
            file_url: lms_file.file_url,
            file_name: lms_file.file_name,
            submission_id: submission.id
          }
        }
      else
        { success: false, message: upload_result[:error] || "File upload failed" }
      end

    rescue => e
      { success: false, message: "Upload failed: #{e.message}" }
    end
  end

  def self.grade(assignment_name, score, user)
    return { error: "User not authenticated" } unless user

    assignment = LmsAssignment.find_by(name: assignment_name)
    return { error: "Assignment not found" } unless assignment

    # Find user's submission
    submission = LmsAssignmentSubmission.find_by(
      assignment: assignment,
      student_id: user.id
    )

    return { error: "Submission not found" } unless submission

    submission.marks_obtained = score
    submission.status = "Completed"
    submission.graded_at = Time.current
    submission.graded_by_id = user.id

    if submission.save
      {
        success: true,
        message: "Assignment graded successfully",
        submission: submission
      }
    else
      {
        error: "Failed to grade assignment",
        details: submission.errors.full_messages
      }
    end
  rescue => e
    {
      error: "Failed to grade assignment",
      details: e.message
    }
  end
end
