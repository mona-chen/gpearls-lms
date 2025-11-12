class FileInfoService
  def self.call(file_url)
    begin
      return { error: "File URL required" } unless file_url.present?

      # Try to find the file in the database first
      lms_file = LmsFile.find_by(file_url: file_url)

      if lms_file
        {
          file_name: lms_file.file_name,
          file_url: lms_file.file_url,
          file_type: lms_file.file_type || lms_file.content_type_from_extension,
          file_size: lms_file.file_size,
          is_private: lms_file.is_private,
          uploaded_by: lms_file.uploaded_by&.full_name,
          uploaded_at: lms_file.uploaded_at&.strftime("%Y-%m-%d %H:%M:%S")
        }
      else
        # Fallback: try to get file info from the file system
        file_path = Rails.root.join("public", file_url.sub(/\A\//, ""))

        if File.exist?(file_path)
          {
            file_name: File.basename(file_url),
            file_url: file_url,
            file_type: content_type_from_path(file_path),
            file_size: File.size(file_path),
            is_private: false,
            uploaded_by: nil,
            uploaded_at: File.mtime(file_path).strftime("%Y-%m-%d %H:%M:%S")
          }
        else
          { error: "File not found" }
        end
      end
    rescue => e
      { error: "Failed to get file info: #{e.message}" }
    end
  end

  private

  def self.content_type_from_path(file_path)
    case File.extname(file_path).downcase
    when ".pdf" then "application/pdf"
    when ".doc" then "application/msword"
    when ".docx" then "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    when ".xls" then "application/vnd.ms-excel"
    when ".xlsx" then "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    when ".ppt" then "application/vnd.ms-powerpoint"
    when ".pptx" then "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    when ".txt" then "text/plain"
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".png" then "image/png"
    when ".gif" then "image/gif"
    when ".zip" then "application/zip"
    else "application/octet-stream"
    end
  end
end
