module Notifications
  class AnnouncementsService
    def self.call(params = {})
      new(params).call
    end

    def initialize(params = {})
      @params = params
    end

    def call
      announcements = Announcement.includes(:author)
                                  .order(created_at: :desc)

      # Apply filters
      announcements = apply_filters(announcements)

      # Apply pagination
      announcements = apply_pagination(announcements)

      announcements_data = announcements.map do |announcement|
        format_announcement(announcement)
      end

      { "data" => announcements_data }
    end

    private

    def apply_filters(announcements)
      return announcements unless @params[:filters].present?

      filters = @params[:filters]

      # Filter by batch if specified
      if filters[:batch].present?
        batch = Batch.find_by(id: filters[:batch])
        announcements = announcements.where(batch: batch) if batch
      end

      # Filter by course if specified
      if filters[:course].present?
        course = Course.find_by(id: filters[:course])
        announcements = announcements.where(course: course) if course
      end

      # Filter by date range
      if filters[:from_date].present?
        announcements = announcements.where("created_at >= ?", Date.parse(filters[:from_date]))
      end

      if filters[:to_date].present?
        announcements = announcements.where("created_at <= ?", Date.parse(filters[:to_date]))
      end

      # Filter by announcement type
      if filters[:type].present?
        announcements = announcements.where(announcement_type: filters[:type])
      end

      announcements
    end

    def apply_pagination(announcements)
      limit = (@params[:limit] || 20).to_i.clamp(1, 100)
      offset = (@params[:start] || 0).to_i

      announcements.limit(limit).offset(offset)
    end

    def format_announcement(announcement)
      {
        name: announcement.id,
        title: announcement.title,
        content: announcement.content,
        announcement_type: announcement.announcement_type,
        batch: announcement.batch&.name,
        course: announcement.course&.title,
        author: announcement.author&.full_name,
        published: announcement.published,
        creation: announcement.created_at.strftime("%Y-%m-%d %H:%M:%S"),
        modified: announcement.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
        read_by_count: announcement.read_receipts&.count || 0,
        attachments: announcement.attachments || []
      }
    end
  end
end
