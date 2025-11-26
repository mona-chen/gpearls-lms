module System
  class FileUploadService
    def self.call(request, current_user)
      begin
        file = request.params[:file] || request.params[:filedata]

        return {
          status: "error",
          message: "No file provided"
        } unless file && file.respond_to?(:tempfile)

        uploaded_file = process_upload(file, current_user)

        if uploaded_file[:success]
          # Create LmsFile record
          lms_file = create_file_record(uploaded_file, current_user)

          {
            status: "success",
            message: "File uploaded successfully",
            data: {
              file_url: uploaded_file[:file_url],
              file_name: uploaded_file[:file_name],
              file_type: uploaded_file[:file_type],
              file_size: uploaded_file[:file_size],
              file_id: lms_file.id
            }
          }
        else
          {
            status: "error",
            message: uploaded_file[:error] || "Upload failed"
          }
        end

      rescue => e
        {
          status: "error",
          message: "File upload failed: " + e.message
        }
      end
    end

    private

    def self.process_upload(file, current_user)
      begin
        original_filename = file.original_filename
        file_extension = File.extname(original_filename)
        filename = Time.current.to_i.to_s + "_" + (0...8).map { ("a".."z").to_a[rand(26)] }.join + file_extension

        # Create upload directory if it doesn't exist
        upload_dir = Rails.root.join("public", "uploads", "files")
        FileUtils.mkdir_p(upload_dir)

        file_path = File.join(upload_dir, filename)

        # Write file to disk
        File.open(file_path, "wb") do |f|
          f.write(file.read)
        end

        # Validate file type and size
        validation_result = validate_file(file, original_filename)
        unless validation_result[:valid]
          File.delete(file_path) if File.exist?(file_path)
          return {
            success: false,
            error: validation_result[:error]
          }
        end

        {
          success: true,
          file_url: "/uploads/files/" + filename,
          file_name: original_filename,
          file_type: file.content_type,
          file_size: file.size,
          file_path: file_path
        }
      rescue => e
        {
          success: false,
          error: "File processing failed: #{e.message}"
        }
      end
    end

    def self.validate_file(file, filename)
      # Check file size (max 10MB)
      max_size = 10.megabytes
      if file.size > max_size
        return { valid: false, error: "File size exceeds maximum allowed size (10MB)" }
      end

      # Check file type
      allowed_types = [
        # Documents
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.ms-excel",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "text/plain",
        "text/csv",

        # Images
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/webp",

        # Archives
        "application/zip",
        "application/x-zip-compressed",

        # Code files
        "text/x-python",
        "text/x-java",
        "text/javascript",
        "text/html",
        "text/css",
        "application/json"
      ]

      # Also check file extension for additional security
      allowed_extensions = [
        ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".txt", ".csv",
        ".jpg", ".jpeg", ".png", ".gif", ".webp",
        ".zip",
        ".py", ".java", ".js", ".html", ".css", ".json"
      ]

      file_extension = File.extname(filename).downcase

      unless allowed_types.include?(file.content_type) || allowed_extensions.include?(file_extension)
        return { valid: false, error: "File type not allowed" }
      end

      # Check for malicious file names
      if filename.include?("..") || filename.include?("/") || filename.include?("\\")
        return { valid: false, error: "Invalid file name" }
      end

      { valid: true }
    end

    def self.create_file_record(uploaded_file, current_user)
      LmsFile.create!(
        file_name: uploaded_file[:file_name],
        file_url: uploaded_file[:file_url],
        file_type: uploaded_file[:file_type],
        file_size: uploaded_file[:file_size],
        uploaded_by: current_user,
        is_private: false # Default to public, can be changed based on requirements
      )
    end
  end
end
