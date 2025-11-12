class Api::WorkflowsController < ApplicationController
  before_action :authenticate_user!

  def get_workflow_actions
    document_type = params[:document_type]
    document_name = params[:document_name]

    # Find the document (e.g., Course)
    document = find_document(document_type, document_name)
    return render json: { error: "Document not found" }, status: :not_found unless document

    actions = Workflows::WorkflowsService.get_available_actions(document, current_user)

    render json: { actions: actions }
  end

  def apply_workflow_action
    document_type = params[:document_type]
    document_name = params[:document_name]
    action = params[:action]

    document = find_document(document_type, document_name)
    return render json: { error: "Document not found" }, status: :not_found unless document

    success = Workflows::WorkflowsService.apply_action(document, action, current_user)

    if success
      render json: { message: "Action applied successfully", workflow_state: document.workflow_state }
    else
      render json: { error: "Action not allowed" }, status: :forbidden
    end
  end

  private

  def find_document(document_type, document_name)
    case document_type
    when "Course"
      Course.find_by(name: document_name)
    when "JobOpportunity"
      JobOpportunity.find_by(name: document_name)
    else
      nil
    end
  end
end
