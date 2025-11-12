module Batches
  class BatchTimetableService
    def self.call(batch_name, start_date: nil, end_date: nil)
      new(batch_name, start_date, end_date).call
    end

    def initialize(batch_name, start_date, end_date)
      @batch_name = batch_name
      @start_date = start_date
      @end_date = end_date
    end

    def call
      # Find batch by name (parameterized title), title, or id
      batch = Batch.find_by(title: @batch_name) ||
              Batch.find_by(id: @batch_name) ||
              Batch.where("title LIKE ?", @batch_name.tr("_", " ")).first
      return [] unless batch

      # Get batch timetable entries
      timetable_entries = batch.batch_timetables.includes(:reference_doc)
                               .order(:date, :start_time)

      # Apply date filters
      if @start_date
        timetable_entries = timetable_entries.where("date >= ?", @start_date)
      end

      if @end_date
        timetable_entries = timetable_entries.where("date <= ?", @end_date)
      end

      # Include live classes if enabled
      live_classes = []
      if batch.show_live_class
        live_classes_query = batch.live_classes.order(:date, :time)

        if @start_date
          live_classes_query = live_classes_query.where("date >= ?", @start_date)
        end

        if @end_date
          live_classes_query = live_classes_query.where("date <= ?", @end_date)
        end

        live_classes = live_classes_query.map do |live_class|
          {
            name: live_class.id,
            title: live_class.title,
            date: live_class.date&.strftime("%Y-%m-%d"),
            start_time: live_class.time&.strftime("%H:%M:%S"),
            end_time: (live_class.time + live_class.duration.minutes)&.strftime("%H:%M:%S"),
            reference_doctype: "LMS Live Class",
            reference_docname: live_class.name,
            url: live_class.join_url,
            duration: live_class.duration,
            milestone: false,
            creation: live_class.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
            modified: live_class.updated_at&.strftime("%Y-%m-%d %H:%M:%S")
          }
        end
      end

      # Format timetable entries
      timetable_data = timetable_entries.map do |entry|
        {
          name: entry.id,
          title: entry.get_title,
          date: entry.date&.strftime("%Y-%m-%d"),
          start_time: entry.start_time&.strftime("%H:%M:%S"),
          end_time: entry.end_time&.strftime("%H:%M:%S"),
          reference_doctype: entry.reference_doctype,
          reference_docname: entry.reference_docname,
          milestone: entry.milestone,
          creation: entry.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
          modified: entry.updated_at&.strftime("%Y-%m-%d %H:%M:%S")
        }
      end

      # Combine and sort by date and time
      all_entries = (timetable_data + live_classes).sort_by do |entry|
        [ entry[:date], entry[:start_time] || entry[:time] ]
      end

      all_entries
    end
  end
end
