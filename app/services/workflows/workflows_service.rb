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
    return { success: false, error: "Invalid transition" } unless transition

    allowed_roles = transition.allowed_roles&.split(",")&.map(&:strip) || []
    if allowed_roles.any?
      user_roles = user.roles || []
      return { success: false, error: "Insufficient permissions" } unless (allowed_roles & user_roles).any?
    end

    # Execute transition
    old_state = document.workflow_state
    document.update(workflow_state: transition.next_state)

    # Create workflow action record (if you have a WorkflowAction model)
    # WorkflowAction.create!(
    #   document: document,
    #   user: user,
    #   action: action,
    #   from_state: old_state,
    #   to_state: transition.next_state,
    #   transition: transition
    # )

    # Execute any post-transition actions
    execute_post_transition_actions(document, transition, user)

    { success: true, message: "Action '#{action}' applied successfully", new_state: transition.next_state }
  end

  def self.execute_post_transition_actions(document, transition, user)
    # Execute any automated actions after transition
    case document.class.name
    when "Course"
      execute_course_workflow_actions(document, transition, user)
    when "Batch"
      execute_batch_workflow_actions(document, transition, user)
    end
  end

  def self.execute_course_workflow_actions(course, transition, user)
    case transition.next_state
    when "Approved"
      # Send approval notifications
      notify_course_approved(course, user)
      # Make course published
      course.update(published: true, published_at: Time.current)
    when "Rejected"
      # Send rejection notifications
      notify_course_rejected(course, user)
    end
  end

  def self.execute_batch_workflow_actions(batch, transition, user)
    case transition.next_state
    when "Approved"
      # Send approval notifications
      notify_batch_approved(batch, user)
      # Make batch published
      batch.update(published: true)
    when "Rejected"
      # Send rejection notifications
      notify_batch_rejected(batch, user)
    end
  end

  def self.notify_course_approved(course, user)
    # Send notifications to course creator and administrators
    # This would integrate with your notification system
    puts "Course #{course.title} approved by #{user.email}"
  end

  def self.notify_course_rejected(course, user)
    # Send rejection notification
    puts "Course #{course.title} rejected by #{user.email}"
  end

  def self.notify_batch_approved(batch, user)
    # Send notifications to batch creator and administrators
    puts "Batch #{batch.title} approved by #{user.email}"
  end

  def self.notify_batch_rejected(batch, user)
    # Send rejection notification
    puts "Batch #{batch.title} rejected by #{user.email}"
  end
  end
end
