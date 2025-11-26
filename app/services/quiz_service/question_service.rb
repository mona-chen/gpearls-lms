# frozen_string_literal: true

module QuizService
  class QuestionService
    # Exact implementation of get_question_details from Frappe Python backend
    # lms/lms/utils.py:1442-1450
    def self.get_details(question_name)
      # Frappe implementation:
      # def get_question_details(question):
      #   fields = ["question", "type", "multiple"]
      #   for i in range(1, 5):
      #     fields.append(f"option_{i}")
      #     fields.append(f"explanation_{i}")
      #   question_details = frappe.db.get_value("LMS Question", question, fields, as_dict=1)
      #   return question_details

      question = LmsQuestion.find_by(name: question_name)
      return { error: "Question not found" } unless question

      # Build the exact field list that Frappe uses
      fields = %w[question question_type multiple]
      (1..4).each do |i|
        fields << "option_#{i}"
        fields << "explanation_#{i}"
      end

      # Get values exactly as Frappe would
      question_details = {}
      fields.each do |field|
        question_details[field] = question.send(field)
      end

      # Format exactly like Frappe returns
      question_details
    rescue => e
      {
        error: "Failed to get question details",
        details: e.message
      }
    end

    # Helper method to create questions following Frappe patterns
    def self.create_question(params, user = nil)
      return { error: "User not authenticated" } unless user
      return { error: "Question text is required" } unless params[:question].present?

      # Generate Frappe-style name if not provided
      question_name = params[:name] || generate_frappe_name

      # Check if name already exists
      if LmsQuestion.exists?(name: question_name)
        return { error: "Question name already exists" }
      end

      question = LmsQuestion.new(
        name: question_name,
        question: params[:question],
        type: params[:type] || "Choices",
        multiple: params[:multiple] || false,
        owner: user&.email,
        marks: params[:marks] || 1,
        is_mandatory: params[:is_mandatory] || false
      )

      # Set options for choice questions (Frappe style)
      if [ "Choices", "Multiple Choice" ].include?(question.type)
        (1..4).each do |i|
          question.send("option_#{i}=", params.dig(:options, i-1) || "")
          question.send("explanation_#{i}=", params.dig(:explanations, i-1) || "")
          question.send("is_correct_#{i}=", params.dig(:is_correct, i-1) || false)
        end
      end

      if question.save
        {
          success: true,
          message: "Question created successfully",
          question: get_details(question.name)
        }
      else
        {
          error: "Failed to create question",
          details: question.errors.full_messages
        }
      end
    rescue => e
      {
        error: "Failed to create question",
        details: e.message
      }
    end

    # Helper method to update questions following Frappe patterns
    def self.update_question(question_name, params, user = nil)
      return { error: "User not authenticated" } unless user

      question = LmsQuestion.find_by(name: question_name)
      return { error: "Question not found" } unless question

      # Check permissions - only owner or admin can update
      unless question.owner == user.email || user.roles.exists?(name: "Administrator")
        return { error: "Permission denied" }
      end

      # Update basic fields
      question.question = params[:question] if params[:question].present?
      question.type = params[:type] if params[:type].present?
      question.multiple = params[:multiple] if params[:multiple].present?
      question.marks = params[:marks] if params[:marks].present?
      question.is_mandatory = params[:is_mandatory] if params[:is_mandatory].present?

      # Update options for choice questions
      if [ "Choices", "Multiple Choice" ].include?(question.type)
        (1..4).each do |i|
          if params.dig(:options, i-1).present?
            question.send("option_#{i}=", params.dig(:options, i-1))
          end
          if params.dig(:explanations, i-1).present?
            question.send("explanation_#{i}=", params.dig(:explanations, i-1))
          end
          if params.dig(:is_correct, i-1).present?
            question.send("is_correct_#{i}=", params.dig(:is_correct, i-1))
          end
        end
      end

      if question.save
        {
          success: true,
          message: "Question updated successfully",
          question: get_details(question.name)
        }
      else
        {
          error: "Failed to update question",
          details: question.errors.full_messages
        }
      end
    rescue => e
      {
        error: "Failed to update question",
        details: e.message
      }
    end

    # Helper method to delete questions following Frappe patterns
    def self.delete_question(question_name, user = nil)
      return { error: "User not authenticated" } unless user

      question = LmsQuestion.find_by(name: question_name)
      return { error: "Question not found" } unless question

      # Check permissions - only owner or admin can delete
      unless question.owner == user.email || user.roles.exists?(name: "Administrator")
        return { error: "Permission denied" }
      end

      # Check if question is used in any active quizzes
      if question.lms_quiz_questions.joins(:lms_quiz).where(lms_quizzes: { status: "Published" }).any?
        return { error: "Cannot delete question - it is used in active quizzes" }
      end

      question.destroy

      {
        success: true,
        message: "Question deleted successfully"
      }
    rescue => e
      {
        error: "Failed to delete question",
        details: e.message
      }
    end

    # Search questions following Frappe patterns
    def self.search_questions(query, options = {})
      questions = LmsQuestion.all

      # Apply search filter
      if query.present?
        questions = questions.where("question ILIKE ? OR name ILIKE ?", "%#{query}%", "%#{query}%")
      end

      # Apply other filters
      questions = questions.where(type: options[:type]) if options[:type].present?
      questions = questions.where(owner: options[:owner]) if options[:owner].present?
      questions = questions.where(is_mandatory: options[:is_mandatory]) if options[:is_mandatory].present?

      # Apply pagination
      limit = options[:limit] || 50
      offset = options[:offset] || 0
      questions = questions.limit(limit).offset(offset)

      # Order by creation date
      questions = questions.order(created_at: :desc)

      {
        success: true,
        questions: questions.map { |q| get_details(q.name) },
        total: questions.count
      }
    rescue => e
      {
        error: "Failed to search questions",
        details: e.message
      }
    end

    private

    # Generate Frappe-style question name: QTS-YYYY-#####
    def self.generate_frappe_name
      year = Time.current.year
      # Use parameterized query to prevent SQL injection
      count = LmsQuestion.where("name LIKE ?", "QTS-#{year}-%").count + 1
      "QTS-#{year}-#{count.to_s.rjust(5, '0')}"
    end
  end
end
