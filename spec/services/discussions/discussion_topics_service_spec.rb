require 'rails_helper'

RSpec.describe Discussions::DiscussionTopicsService, type: :service do
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let!(:discussion1) { create(:discussion, user: user, course: course, status: 'open') }
  let!(:discussion2) { create(:discussion, user: user, course: course, status: 'closed') }
  let!(:message1) { create(:message, user: user, discussion: discussion1) }
  let!(:message2) { create(:message, user: user, discussion: discussion1) }

  describe '.call' do
    context 'without filters' do
      it 'returns all open discussions with Frappe-compatible format' do
        result = described_class.call

        expect(result).to have_key('data')
        expect(result['data'].length).to eq(1) # Only open discussion

        discussion_data = result['data'].first
        expect(discussion_data).to include(
          'name' => discussion1.id,
          'title' => discussion1.title,
          'content' => discussion1.content,
          'status' => 'open',
          'course' => course.id,
          'course_title' => course.title,
          'owner' => user.email,
          'reply_count' => 2,
          'creation' => discussion1.created_at.strftime('%Y-%m-%d %H:%M:%S')
        )
      end
    end

    context 'with course filter' do
      let(:other_course) { create(:course) }
      let!(:other_discussion) { create(:discussion, user: user, course: other_course, status: 'open') }

      it 'filters discussions by course' do
        params = { course: course.id }
        result = described_class.call(params)

        expect(result['data'].length).to eq(1)
        expect(result['data'].first['course']).to eq(course.id)
      end

      it 'filters discussions by course title' do
        params = { course: course.title }
        result = described_class.call(params)

        expect(result['data'].length).to eq(1)
        expect(result['data'].first['course_title']).to eq(course.title)
      end
    end

    context 'with status filter' do
      it 'filters by specific status' do
        params = { status: 'closed' }
        result = described_class.call(params)

        expect(result['data'].length).to eq(1)
        expect(result['data'].first['status']).to eq('closed')
      end

      it 'returns all statuses when status filter is provided' do
        params = { status: [ 'open', 'closed' ] }
        result = described_class.call(params)

        expect(result['data'].length).to eq(2)
        statuses = result['data'].map { |d| d['status'] }
        expect(statuses).to include('open', 'closed')
      end
    end

    context 'with pagination' do
      let!(:discussion3) { create(:discussion, user: user, course: course, status: 'open') }

      it 'applies limit' do
        params = { limit: 1 }
        result = described_class.call(params)

        expect(result['data'].length).to eq(1)
      end

      it 'applies offset' do
        params = { start: 1, limit: 1 }
        result = described_class.call(params)

        expect(result['data'].length).to eq(1)
      end
    end

    context 'with ordering' do
      let!(:older_discussion) { create(:discussion, user: user, course: course, status: 'open', created_at: 1.day.ago) }

      it 'orders by creation date descending by default' do
        result = described_class.call

        expect(result['data'].first['name']).to eq(discussion1.id) # Most recent first
      end

      it 'orders by custom field' do
        params = { order_by: 'title ASC' }
        result = described_class.call(params)

        expect(result).to have_key('data')
      end
    end

    context 'reply count and last reply' do
      it 'includes correct reply count' do
        result = described_class.call

        discussion_data = result['data'].first
        expect(discussion_data['reply_count']).to eq(2)
      end

      it 'includes last reply timestamp' do
        result = described_class.call

        discussion_data = result['data'].first
        expect(discussion_data['last_reply_at']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end

      it 'includes last reply author' do
        result = described_class.call

        discussion_data = result['data'].first
        expect(discussion_data['last_reply_by']).to eq(user.full_name)
      end
    end

    context 'Frappe API compatibility' do
      it 'returns exact field structure matching Frappe LMS' do
        result = described_class.call
        discussion_data = result['data'].first

        expected_fields = [
          'name', 'title', 'content', 'status', 'course', 'course_title',
          'owner', 'owner_name', 'reply_count', 'last_reply_at', 'last_reply_by',
          'creation', 'modified'
        ]

        expected_fields.each do |field|
          expect(discussion_data).to have_key(field), "Missing field: #{field}"
        end
      end

      it 'formats dates correctly' do
        result = described_class.call
        discussion_data = result['data'].first

        expect(discussion_data['creation']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(discussion_data['modified']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(discussion_data['last_reply_at']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end
    end
  end
end
