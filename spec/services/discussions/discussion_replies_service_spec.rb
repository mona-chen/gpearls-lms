require 'rails_helper'

RSpec.describe Discussions::DiscussionRepliesService, type: :service do
  let(:user) { create(:user) }
  let(:discussion) { create(:discussion, user: user) }
  let!(:root_message1) { create(:message, user: user, discussion: discussion, message_type: 'text') }
  let!(:root_message2) { create(:message, user: user, discussion: discussion, message_type: 'text') }
  let!(:reply_message) { create(:message, user: user, discussion: discussion, parent_message: root_message1, message_type: 'text') }
  let!(:review_message) { create(:message, user: user, discussion: discussion, message_type: 'review') }

  describe '.call' do
    context 'with valid discussion' do
      it 'returns root messages by default' do
        result = described_class.call(discussion.id)

        expect(result).to have_key('data')
        expect(result['data'].length).to eq(2) # root_message1 and root_message2

        message_ids = result['data'].map { |m| m['name'] }
        expect(message_ids).to include(root_message1.id, root_message2.id)
        expect(message_ids).not_to include(reply_message.id)
      end

      it 'includes replies for each message' do
        result = described_class.call(discussion.id)

        root_message_data = result['data'].find { |m| m['name'] == root_message1.id }
        expect(root_message_data['replies'].length).to eq(1)
        expect(root_message_data['replies'].first['name']).to eq(reply_message.id)
      end
    end

    context 'with parent message filter' do
      it 'returns replies to specific message' do
        params = { parent_message: root_message1.id }
        result = described_class.call(discussion.id, params)

        expect(result['data'].length).to eq(1)
        expect(result['data'].first['name']).to eq(reply_message.id)
        expect(result['data'].first['parent_message']).to eq(root_message1.id)
      end
    end

    context 'with message type filter' do
      it 'filters by message type' do
        params = { message_type: 'review' }
        result = described_class.call(discussion.id, params)

        expect(result['data'].length).to eq(1)
        expect(result['data'].first['message_type']).to eq('review')
      end
    end

    context 'with pagination' do
      let!(:root_message3) { create(:message, user: user, discussion: discussion, message_type: 'text') }

      it 'applies limit' do
        params = { limit: 1 }
        result = described_class.call(discussion.id, params)

        expect(result['data'].length).to eq(1)
      end

      it 'applies offset' do
        params = { start: 1, limit: 1 }
        result = described_class.call(discussion.id, params)

        expect(result['data'].length).to eq(1)
      end
    end

    context 'with ordering' do
      let!(:older_message) { create(:message, user: user, discussion: discussion, message_type: 'text', created_at: 1.day.ago) }

      it 'orders by creation date descending by default' do
        result = described_class.call(discussion.id)

        expect(result['data'].first['name']).to eq(root_message2.id) # Most recent first
      end

      it 'orders by custom field' do
        params = { order_by: 'content ASC' }
        result = described_class.call(discussion.id, params)

        expect(result).to have_key('data')
      end
    end

    context 'with invalid discussion' do
      it 'returns empty array for non-existent discussion' do
        result = described_class.call('non-existent-discussion')

        expect(result['data']).to eq([])
      end
    end

    context 'Frappe API compatibility' do
      it 'returns exact field structure matching Frappe LMS' do
        result = described_class.call(discussion.id)
        message_data = result['data'].first

        expected_fields = [
          'name', 'content', 'message_type', 'discussion', 'owner',
          'owner_name', 'parent_message', 'reply_count', 'last_reply_at',
          'creation', 'modified', 'replies'
        ]

        expected_fields.each do |field|
          expect(message_data).to have_key(field), "Missing field: #{field}"
        end
      end

      it 'formats dates correctly' do
        result = described_class.call(discussion.id)
        message_data = result['data'].first

        expect(message_data['creation']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(message_data['modified']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end

      it 'includes reply count' do
        result = described_class.call(discussion.id)

        root_message_data = result['data'].find { |m| m['name'] == root_message1.id }
        expect(root_message_data['reply_count']).to eq(1)
      end
    end
  end
end
