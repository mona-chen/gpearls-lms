require 'rails_helper'

RSpec.describe Discussions::SaveMessageService, type: :service do
  let(:user) { create(:user) }
  let(:discussion) { create(:discussion, user: user, status: 'open') }

  describe '.call' do
    context 'successful message creation' do
      let(:params) { { discussion: discussion.id, content: 'This is a test message' } }

      it 'creates a message' do
        expect {
          result = described_class.call(params, user)
          expect(result[:success]).to be_truthy
        }.to change(Message, :count).by(1)
      end

      it 'returns success response with message data' do
        result = described_class.call(params, user)

        expect(result[:success]).to be_truthy
        expect(result[:data]).to be_a(Message)
        expect(result[:message]).to eq('Message saved successfully')
      end

      it 'sets default message type to text' do
        result = described_class.call(params, user)

        message = result[:data]
        expect(message.message_type).to eq('text')
        expect(message.content).to eq('This is a test message')
        expect(message.user).to eq(user)
        expect(message.discussion).to eq(discussion)
      end

      it 'allows custom message type' do
        custom_params = params.merge(message_type: 'image')
        result = described_class.call(custom_params, user)

        message = result[:data]
        expect(message.message_type).to eq('image')
      end
    end

    context 'reply message creation' do
      let(:parent_message) { create(:message, user: user, discussion: discussion) }
      let(:reply_params) { { discussion: discussion.id, content: 'This is a reply', parent_message: parent_message.id } }

      it 'creates a reply message' do
        result = described_class.call(reply_params, user)

        expect(result[:success]).to be_truthy
        message = result[:data]
        expect(message.parent_message).to eq(parent_message)
        expect(message.reply?).to be_truthy
      end
    end

    context 'validation failures' do
      it 'fails for nil user' do
        result = described_class.call({ discussion: discussion.id, content: 'test' }, nil)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('User not found')
      end

      it 'fails for missing discussion' do
        result = described_class.call({ content: 'test' }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Discussion ID is required')
      end

      it 'fails for missing content' do
        result = described_class.call({ discussion: discussion.id }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Content is required')
      end

      it 'fails for non-existent discussion' do
        result = described_class.call({ discussion: 'non-existent', content: 'test' }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Discussion not found')
      end

      it 'fails for closed discussion' do
        discussion.update(status: 'closed')
        result = described_class.call({ discussion: discussion.id, content: 'test' }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Discussion is closed')
      end

      it 'fails for non-existent parent message' do
        result = described_class.call({
          discussion: discussion.id,
          content: 'test',
          parent_message: 'non-existent'
        }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Parent message not found')
      end

      it 'fails for parent message in different discussion' do
        other_discussion = create(:discussion, user: user)
        parent_message = create(:message, user: user, discussion: other_discussion)

        result = described_class.call({
          discussion: discussion.id,
          content: 'test',
          parent_message: parent_message.id
        }, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Parent message is not in this discussion')
      end
    end

    context 'Frappe API compatibility' do
      it 'returns proper success response format' do
        params = { discussion: discussion.id, content: 'test message' }
        result = described_class.call(params, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:data)
        expect(result).to have_key(:message)
        expect(result[:success]).to be_truthy
      end

      it 'returns proper error response format' do
        result = described_class.call({}, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:error)
        expect(result).to have_key(:message)
        expect(result[:success]).to be_falsey
      end
    end
  end
end
