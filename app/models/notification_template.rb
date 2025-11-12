class NotificationTemplate < ApplicationRecord
  # Frappe-compatible notification template model
  belongs_to :created_by, class_name: "User", optional: true

  validates :name, :subject, :message, presence: true
  validates :name, uniqueness: true

  # Template types matching Frappe
  enum template_type: {
    email: 0,
    system: 1,
    both: 2
  }

  # Event types that trigger notifications
  enum event_type: {
    document_created: 0,
    document_updated: 1,
    document_submitted: 2,
    document_cancelled: 3,
    days_before: 4,
    days_after: 5,
    value_changed: 6,
    custom: 7
  }

  # Document types this template applies to
  validates :document_type, presence: true

  # Recipients configuration (stored as JSON)
  serialize :recipients, JSON

  # Conditions for when to send (stored as JSON)
  serialize :conditions, JSON

  def self.find_by_document_and_event(document_type, event_type)
    where(document_type: document_type, event_type: event_type)
  end

  def should_send?(document)
    return true unless conditions.present?

    # Evaluate conditions against document
    evaluate_conditions(document)
  end

  def render_message(document, recipient = nil)
    template_vars = build_template_variables(document, recipient)
    ERB.new(message).result_with_hash(template_vars)
  end

  def render_subject(document, recipient = nil)
    template_vars = build_template_variables(document, recipient)
    ERB.new(subject).result_with_hash(template_vars)
  end

  private

  def evaluate_conditions(document)
    # Simple condition evaluation - can be extended
    conditions.each do |condition|
      field = condition["field"]
      operator = condition["operator"]
      value = condition["value"]

      document_value = document.send(field) if document.respond_to?(field)

      case operator
      when "equals"
        return false unless document_value.to_s == value.to_s
      when "not_equals"
        return false if document_value.to_s == value.to_s
      when "contains"
        return false unless document_value.to_s.include?(value.to_s)
      end
    end
    true
  end

  def build_template_variables(document, recipient = nil)
    {
      doc: document,
      recipient: recipient,
      frappe: FrappeHelper.new,
      _doc: document, # Alias for backward compatibility
      _recipient: recipient
    }
  end
end
