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

        upload_dir = Rails.root.join("public", "uploads", "files")
        FileUtils.mkdir_p(upload_dir) unless Dir.exist?(upload_dir)

        file_path = File.join(upload_dir, filename)
        File.open(file_path, "wb") { |f| f.write(file.tempfile.read) }

        {
          success: true,
          file_url: "/uploads/files/" + filename,
          file_name: original_filename,
          file_type: file.content_type,
          file_size: file.size
        }

      rescue => e
        {
          success: false,
          error: e.message
        }
      end
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
