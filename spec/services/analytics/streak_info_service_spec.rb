require 'rails_helper'

RSpec.describe Analytics::StreakInfoService do
  describe '.call' do
    let(:user) { create(:user) }
    let(:lesson) { create(:lesson) }

    context 'when user has no activity' do
      it 'returns zero streaks' do
        result = described_class.call(user)

        expect(result[:current_streak]).to eq(0)
        expect(result[:longest_streak]).to eq(0)
        expect(result[:total_days]).to eq(0)
        expect(result[:last_activity_date]).to be_nil
      end
    end

    context 'when user has activity' do
      before do
        # Create lesson progress for the last 5 days
        5.times do |i|
          create(:lesson_progress,
                 user: user,
                 lesson: lesson,
                 last_accessed_at: i.days.ago,
                 status: 'Complete')
        end
      end

      it 'calculates current and longest streak' do
        result = described_class.call(user)

        expect(result[:current_streak]).to eq(5)
        expect(result[:longest_streak]).to eq(5)
        expect(result[:total_days]).to eq(5)
        expect(result[:last_activity_date]).to be_present
      end
    end

    context 'when no user provided' do
      it 'returns default streak info' do
        result = described_class.call(nil)

        expect(result[:current_streak]).to eq(0)
        expect(result[:longest_streak]).to eq(0)
        expect(result[:total_days]).to eq(0)
        expect(result[:last_activity_date]).to be_nil
      end
    end

    context 'when user has broken streak' do
      before do
        # Create activity for days 1, 2, 3, then gap, then day 7, 8
        [ 1, 2, 3, 7, 8 ].each do |days_ago|
          create(:lesson_progress,
                 user: user,
                 lesson: lesson,
                 last_accessed_at: days_ago.days.ago,
                 status: 'Complete')
        end
      end

      it 'calculates correct current streak' do
        result = described_class.call(user)

        expect(result[:current_streak]).to eq(2) # Days 7 and 8
        expect(result[:longest_streak]).to eq(3) # Days 1, 2, 3
        expect(result[:total_days]).to eq(5)
      end
    end
  end
end
