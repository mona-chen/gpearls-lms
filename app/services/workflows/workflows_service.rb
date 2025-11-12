module Workflows
  class WorkflowsService
    def self.create_default_course_workflow
      workflow = Workflow.find_or_create_by(
        name: "Course Approval Workflow",
        document_type: "Course"
      ) do |w|
        w.is_active = true
      end

      # Create states
      states = [
        { state: "Draft", doc_status: "Draft" },
        { state: "Pending Review", doc_status: "Under Review" },
        { state: "Approved", doc_status: "Approved" },
        { state: "Rejected", doc_status: "Rejected" }
      ]

      states.each do |state_attrs|
        workflow.workflow_states.find_or_create_by(state_attrs)
      end

      # Create transitions
      transitions = [
        { state: "Draft", action: "Submit for Review", next_state: "Pending Review", allowed_roles: "Course Creator" },
        { state: "Pending Review", action: "Approve", next_state: "Approved", allowed_roles: "System Manager,Moderator" },
        { state: "Pending Review", action: "Reject", next_state: "Rejected", allowed_roles: "System Manager,Moderator" },
        { state: "Rejected", action: "Resubmit", next_state: "Pending Review", allowed_roles: "Course Creator" }
      ]

      transitions.each do |transition_attrs|
        workflow.workflow_transitions.find_or_create_by(transition_attrs)
      end

      workflow
    end

    def self.get_available_actions(document, user)
      return [] unless document.workflow

      current_state = document.workflow_state
      document.workflow.workflow_transitions.where(state: current_state).select do |transition|
        allowed_roles = transition.allowed_roles&.split(",")&.map(&:strip) || []
        next true if allowed_roles.empty?

        user_roles = user.roles || []
        (allowed_roles & user_roles).any?
      end.map do |transition|
        {
          action: transition.action,
          next_state: transition.next_state
        }
      end
    end

    def self.apply_action(document, action, user)
      transition = document.workflow&.workflow_transitions&.find_by(state: document.workflow_state, action: action)
      return false unless transition

      allowed_roles = transition.allowed_roles&.split(",")&.map(&:strip) || []
      if allowed_roles.any?
        user_roles = user.roles || []
        return false unless (allowed_roles & user_roles).any?
      end

      document.update(workflow_state: transition.next_state)
    end
  end
end
