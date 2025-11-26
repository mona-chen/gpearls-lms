class Api::FilesController < Api::BaseController
  skip_before_action :authenticate_user!, only: [ :info ]

  def upload
    if params[:file] && params[:doctype] && params[:docname]
      file = params[:file]

      # Simple file upload simulation
      uploaded_file = {
        file_url: "/uploads/#{file.original_filename}",
        file_name: file.original_filename,
        file_size: file.size,
        file_type: file.content_type,
        docname: params[:docname],
        doctype: params[:doctype]
      }

      render json: uploaded_file
    else
      render json: { error: "Missing required parameters" }, status: :bad_request
    end
  end

  def info
    if params[:file_url]
      render json: {
        file_url: params[:file_url],
        file_name: File.basename(params[:file_url]),
        file_type: "application/octet-stream",
        file_size: 0
      }
    else
      render json: { error: "File URL required" }, status: :bad_request
    end
  end
end
