require 'rails_helper'

RSpec.describe Notifications::MarkAsReadService, type: :service do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:notification) { create(:notification, user: user, read: false) }
  let(:other_notification) { create(:notification, user: other_user, read: false) }

  describe '.call' do
    context 'with valid notification and authorized user' do
      it 'marks the notification as read' do
        result = described_class.call(notification.id, user)

        expect(result).to eq({ success: true })
        expect(notification.reload.read).to be true
      end
    end

    context 'with non-existent notification' do
      it 'returns error' do
        result = described_class.call(99999, user)

        expect(result).to eq({ error: 'Notification not found' })
      end
    end

    context 'with notification belonging to different user' do
      it 'returns unauthorized error' do
        result = described_class.call(other_notification.id, user)

        expect(result).to eq({ error: 'Unauthorized' })
        expect(other_notification.reload.read).to be false
      end
    end

    context 'with already read notification' do
      let(:read_notification) { create(:notification, user: user, read: true) }

      it 'still returns success' do
        result = described_class.call(read_notification.id, user)

        expect(result).to eq({ success: true })
        expect(read_notification.reload.read).to be true
      end
    end
  end
end
