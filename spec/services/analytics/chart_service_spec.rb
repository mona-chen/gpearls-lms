require 'rails_helper'

RSpec.describe Analytics::ChartService do
  describe '.call' do
    context 'when requesting New Signups chart' do
      it 'returns signup data for the last 7 days' do
        result = described_class.call('New Signups')

        expect(result).to be_an(Array)
        expect(result.length).to eq(7)

        result.each do |data_point|
          expect(data_point).to have_key(:date)
          expect(data_point).to have_key(:count)
        end
      end
    end

    context 'when requesting Course Enrollments chart' do
      it 'returns enrollment data for the last 7 days' do
        result = described_class.call('Course Enrollments')

        expect(result).to be_an(Array)
        expect(result.length).to eq(7)

        result.each do |data_point|
          expect(data_point).to have_key(:date)
          expect(data_point).to have_key(:count)
        end
      end
    end

    context 'when requesting Certification chart' do
      it 'returns certification data' do
        result = described_class.call('Certification')

        expect(result).to be_an(Array)
        result.each do |data_point|
          expect(data_point).to have_key(:label)
          expect(data_point).to have_key(:count)
        end
      end
    end

    context 'when requesting unknown chart' do
      it 'returns empty array' do
        result = described_class.call('Unknown Chart')

        expect(result).to eq([])
      end
    end

    context 'when no chart name provided' do
      it 'returns all chart data' do
        result = described_class.call(nil)

        expect(result).to have_key('New Signups')
        expect(result).to have_key('Course Enrollments')
        expect(result).to have_key('Certification')

        expect(result['New Signups']).to have_key(:chart_type)
        expect(result['New Signups']).to have_key(:data_points)
      end
    end
  end
end
