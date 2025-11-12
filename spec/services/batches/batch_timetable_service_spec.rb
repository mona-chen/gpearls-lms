require 'rails_helper'

RSpec.describe Batches::BatchTimetableService, type: :service do
  let(:batch) { create(:batch) }
  let(:course) { create(:course) }
  let(:lesson) { create(:lesson) }

  let!(:timetable_entry) {
    create(:batch_timetable,
           batch: batch,
           reference_doctype: 'LMS Lesson',
           reference_docname: lesson.id.to_s,
           date: Date.today,
           start_time: '10:00:00',
           end_time: '11:00:00'
    )
  }

  let!(:live_class) {
    create(:live_class,
           batch: batch,
           title: 'Live Session',
           date: Date.today + 1.day,
           time: '14:00:00',
           duration: 60
    )
  }

  describe '.call' do
    context 'with valid batch' do
      it 'returns timetable entries with Frappe-compatible format' do
        result = described_class.call(batch.name)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2) # timetable entry + live class

        # Check timetable entry
        timetable_data = result.find { |entry| entry['reference_doctype'] == 'LMS Lesson' }
        expect(timetable_data).to include(
          'name' => timetable_entry.id,
          'title' => timetable_entry.get_title,
          'date' => Date.today.strftime('%Y-%m-%d'),
          'start_time' => '10:00:00',
          'end_time' => '11:00:00',
          'reference_doctype' => 'LMS Lesson',
          'reference_docname' => lesson.id.to_s,
          'milestone' => false
        )
      end

      it 'includes live classes when show_live_class is enabled' do
        batch.update(show_live_class: true)
        result = described_class.call(batch.name)

        live_class_data = result.find { |entry| entry['reference_doctype'] == 'LMS Live Class' }
        expect(live_class_data).to include(
          'name' => live_class.id,
          'title' => 'Live Session',
          'date' => (Date.today + 1.day).strftime('%Y-%m-%d'),
          'start_time' => '14:00:00',
          'end_time' => '15:00:00', # 14:00 + 60 minutes
          'reference_doctype' => 'LMS Live Class',
          'reference_docname' => live_class.name,
          'duration' => 60,
          'milestone' => false
        )
      end

      it 'excludes live classes when show_live_class is disabled' do
        batch.update(show_live_class: false)
        result = described_class.call(batch.name)

        live_class_entries = result.select { |entry| entry['reference_doctype'] == 'LMS Live Class' }
        expect(live_class_entries).to be_empty
      end
    end

    context 'with date filters' do
      let!(:past_entry) {
        create(:batch_timetable,
               batch: batch,
               date: Date.today - 7.days,
               start_time: '10:00:00'
        )
      }

      it 'filters by start_date' do
        result = described_class.call(batch.name, start_date: Date.today)

        expect(result.length).to eq(2) # Only current entries, no past entry
        dates = result.map { |entry| entry['date'] }
        expect(dates).to all(be >= Date.today.strftime('%Y-%m-%d'))
      end

      it 'filters by end_date' do
        result = described_class.call(batch.name, end_date: Date.today)

        expect(result.length).to eq(1) # Only the first timetable entry
        expect(result.first['date']).to eq(Date.today.strftime('%Y-%m-%d'))
      end

      it 'filters by both start_date and end_date' do
        result = described_class.call(batch.name,
                                    start_date: Date.today,
                                    end_date: Date.today)

        expect(result.length).to eq(1)
        expect(result.first['date']).to eq(Date.today.strftime('%Y-%m-%d'))
      end
    end

    context 'with invalid batch' do
      it 'returns empty array for non-existent batch' do
        result = described_class.call('non-existent-batch')

        expect(result).to eq([])
      end
    end

    context 'ordering' do
      let!(:later_entry) {
        create(:batch_timetable,
               batch: batch,
               date: Date.today,
               start_time: '15:00:00'
        )
      }

      it 'orders by date and start_time' do
        result = described_class.call(batch.name)

        # Should be ordered: timetable_entry (10:00), live_class (14:00), later_entry (15:00)
        expect(result[0]['start_time']).to eq('10:00:00')
        expect(result[1]['start_time']).to eq('14:00:00')
        expect(result[2]['start_time']).to eq('15:00:00')
      end
    end

    context 'Frappe API compatibility' do
      it 'returns exact field names matching Frappe LMS' do
        result = described_class.call(batch.name)
        entry_data = result.first

        expected_fields = [
          'name', 'title', 'date', 'start_time', 'end_time',
          'reference_doctype', 'reference_docname', 'milestone',
          'creation', 'modified'
        ]

        expected_fields.each do |field|
          expect(entry_data).to have_key(field), "Missing field: #{field}"
        end
      end

      it 'formats dates and times correctly' do
        result = described_class.call(batch.name)
        entry_data = result.first

        expect(entry_data['date']).to match(/\d{4}-\d{2}-\d{2}/)
        expect(entry_data['start_time']).to match(/\d{2}:\d{2}:\d{2}/)
        expect(entry_data['end_time']).to match(/\d{2}:\d{2}:\d{2}/)
        expect(entry_data['creation']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(entry_data['modified']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end
    end
  end
end
