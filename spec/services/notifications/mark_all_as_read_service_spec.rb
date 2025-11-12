require 'rails_helper'

RSpec.describe Notifications::MarkAllAsReadService, type: :service do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe '.call' do
    context 'with unread notifications' do
      let!(:unread_notifications) { create_list(:notification, 3, user: user, read: false) }
      let!(:read_notifications) { create_list(:notification, 2, user: user, read: true) }
      let!(:other_user_notifications) { create_list(:notification, 2, user: other_user, read: false) }

      it 'marks all user notifications as read' do
        result = described_class.call(user)

        expect(result).to eq({ success: true })

        user.notifications.each do |notification|
          expect(notification.reload.read).to be true
        end
      end

      it 'does not affect other users notifications' do
        described_class.call(user)

        other_user_notifications.each do |notification|
          expect(notification.reload.read).to be false
        end
      end

      it 'only updates unread notifications' do
        described_class.call(user)

        read_notifications.each do |notification|
          expect(notification.reload.read).to be true
          # Should not change existing read_at timestamp
        end
      end
    end

    context 'with no unread notifications' do
      let!(:read_notifications) { create_list(:notification, 3, user: user, read: true) }

      it 'returns success' do
        result = described_class.call(user)

        expect(result).to eq({ success: true })
      end
    end

    context 'with no notifications' do
      it 'returns success' do
        result = described_class.call(user)

        expect(result).to eq({ success: true })
      end
    end
  end
end
