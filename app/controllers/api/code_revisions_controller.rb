class Api::CodeRevisionsController < Api::BaseController
  before_action :authenticate_user!

  # POST /api/autosave-section
  def autosave_section
    section = params[:section]
    code = params[:code]

    return render json: { error: "Section and code are required" }, status: :bad_request unless section && code

    begin
      # Parse section to get type and ID
      section_parts = section.split("-")
      section_type = section_parts[0]&.classify
      section_id = section_parts[1]

      revision = CodeRevision.autosave_for_section(section_id, section_type, code, current_user)

      render json: {
        name: revision.id,
        success: true,
        message: "Code saved successfully"
      }
    rescue => e
      Rails.logger.error "Code autosave error: #{e.message}"
      render json: { error: "Failed to save code" }, status: :internal_server_error
    end
  end

  # GET /api/code-revisions/:section
  def get_latest_revision
    section = params[:section]
    section_parts = section.split("-")
    section_type = section_parts[0]&.classify
    section_id = section_parts[1]

    revision = CodeRevision.latest_for_section(section_id, section_type, current_user)

    if revision
      render json: {
        code: revision.code,
        created_at: revision.created_at,
        notes: revision.notes
      }
    else
      render json: { code: "", message: "No previous revision found" }
    end
  end

  # GET /api/code-revisions/history/:section
  def get_revision_history
    section = params[:section]
    section_parts = section.split("-")
    section_type = section_parts[0]&.classify
    section_id = section_parts[1]

    revisions = CodeRevision.where(
      section_id: section_id,
      section_type: section_type,
      user: current_user
    ).order(created_at: :desc).limit(50)

    render json: {
      revisions: revisions.map do |r|
        {
          id: r.id,
          code: r.code,
          created_at: r.created_at,
          notes: r.notes
        }
      end
    }
  end

  # POST /api/code-revisions/:id/restore
  def restore_revision
    revision = current_user.code_revisions.find(params[:id])

    # Create new revision with restored code
    new_revision = CodeRevision.autosave_for_section(
      revision.section_id,
      revision.section_type,
      revision.code,
      current_user
    )

    render json: {
      success: true,
      code: revision.code,
      message: "Code restored successfully"
    }
  end
end
