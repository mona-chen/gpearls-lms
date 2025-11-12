module Discussions
  class DiscussionTopicsService
    def self.call(params = {})
      new(params).call
    end

    def initialize(params = {})
      @params = params
    end

    def call
      discussions = Discussion.includes(:user, :course, :messages)

      # Filter by course if provided
      if @params[:course].present?
        course = Course.find_by(id: @params[:course]) || Course.find_by(title: @params[:course])
        discussions = discussions.where(course: course) if course
      end

      # Filter by status
      if @params[:status].present?
        discussions = discussions.where(status: @params[:status])
      else
        discussions = discussions.open # Default to open discussions
      end

      # Apply ordering
      if @params[:order_by].present?
        discussions = discussions.order(@params[:order_by])
      else
        discussions = discussions.recent
      end

      # Apply pagination
      limit = @params[:limit] || 20
      offset = @params[:start] || 0
      discussions = discussions.limit(limit).offset(offset)

      topics_data = discussions.map do |discussion|
        discussion.to_frappe_format
      end

      { "data" => topics_data }
    end
  end
end
