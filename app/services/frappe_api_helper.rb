# FrappeApiHelper - Utility class to format responses in Frappe-compatible format
module FrappeApiHelper
  extend self

  # Formats response data in Frappe-compatible format
  # @param data [Any] The data to be returned
  # @param status [Integer] Optional HTTP status code
  # @return [Hash] Response in Frappe format
  def format_response(data, status: nil)
    # Frappe expects responses to be wrapped in a message field
    response = { "message" => data }
    response.merge!(status: status) if status
    response
  end

  # Renders a Frappe-formatted JSON response
  # @param controller [ActionController::Base] The controller instance
  # @param data [Any] The data to render
  # @param status [Integer] Optional HTTP status code
  def render_frappe_response(controller, data, status: nil)
    controller.render json: format_response(data, status: status)
  end

  # Common response formats for different data types
  def success_response(data = nil)
    format_response(data || { success: true })
  end

  def error_response(message, status: :unprocessable_entity)
    format_response({ error: message }, status: status)
  end

  def not_found_response(resource = "Resource")
    format_response({ error: "#{resource} not found" }, status: :not_found)
  end

  def unauthorized_response(message = "Unauthorized")
    format_response({ error: message }, status: :unauthorized)
  end

  # Format for list responses (arrays of items)
  def list_response(items, total: nil)
    data = { data: items }
    data[:total] = total if total
    format_response(data)
  end

  # Format for single object responses
  def object_response(object)
    format_response(object)
  end

  # Format for paginated responses
  def paginated_response(items, page: 1, per_page: 20, total: nil)
    total ||= items.count
    data = {
      data: items,
      page: page,
      per_page: per_page,
      total: total
    }
    format_response(data)
  end
end
