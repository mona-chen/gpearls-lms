require 'rails_helper'

RSpec.describe Analytics::HeatmapDataService do
  describe '.call' do
    let(:user) { create(:user) }
    let(:lesson) { create(:lesson) }

    context 'when user has no activity' do
      it 'returns empty heatmap data' do
        result = described_class.call(user)

        expect(result[:heatmap_data]).to be_empty
        expect(result[:total_activities]).to eq(0)
        expect(result[:weeks]).to eq(0)
      end
    end

    context 'when user has activity' do
      before do
        # Create some lesson progress activities
        create_list(:lesson_progress, 3,
                   user: user,
                   lesson: lesson,
                   last_accessed_at: 1.day.ago,
                   status: 'Complete')
      end

      it 'returns heatmap data with activities' do
        result = described_class.call(user)

        expect(result[:heatmap_data]).to be_an(Array)
        expect(result[:total_activities]).to eq(3)
        expect(result[:weeks]).to be > 0

        # Check structure of heatmap data
        expect(result[:heatmap_data].first).to have_key(:name)
        expect(result[:heatmap_data].first).to have_key(:data)
      end
    end

    context 'when no user provided' do
      it 'returns empty data' do
        result = described_class.call(nil)

        expect(result[:heatmap_data]).to be_empty
        expect(result[:total_activities]).to eq(0)
        expect(result[:weeks]).to eq(0)
      end
    end
  end
end
