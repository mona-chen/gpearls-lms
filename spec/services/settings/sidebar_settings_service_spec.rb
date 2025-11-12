# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Settings::SidebarSettingsService, type: :service do
  describe '.call' do
    it 'returns sidebar settings with proper structure' do
      result = described_class.call

      expect(result).to be_a(Hash)
      expect(result['courses']).to be_an(Integer)
      expect(result['batches']).to be_an(Integer)
      expect(result['web_pages']).to be_an(Array)
    end

    it 'returns default sidebar settings (all enabled)' do
      result = described_class.call

      expect(result['courses']).to eq(1)
      expect(result['batches']).to eq(1)
      expect(result['certifications']).to eq(1)
      expect(result['jobs']).to eq(1)
      expect(result['statistics']).to eq(1)
      expect(result['notifications']).to eq(1)
      expect(result['programming_exercises']).to eq(1)
      expect(result['my_courses']).to eq(1)
      expect(result['my_batches']).to eq(1)
      expect(result['profile']).to eq(1)
      expect(result['settings']).to eq(1)
      expect(result['logout']).to eq(1)
      expect(result['web_pages']).to eq([])
    end

    it 'loads sidebar settings from LmsSetting model' do
      # Create test settings (true values should become 1, false values should become 0)
      LmsSetting.create!(key: 'sidebar_courses', value: '0', fieldtype: 'Check')
      LmsSetting.create!(key: 'sidebar_batches', value: '1', fieldtype: 'Check')
      LmsSetting.create!(key: 'sidebar_statistics', value: '0', fieldtype: 'Check')

      result = described_class.call

      expect(result['courses']).to eq(0)
      expect(result['batches']).to eq(1)
      expect(result['statistics']).to eq(0)
      # Other settings should remain default (1)
      expect(result['certifications']).to eq(1)
    end

    it 'converts boolean values to 1/0 format' do
      LmsSetting.create!(key: 'sidebar_jobs', value: 'true', fieldtype: 'Check')
      LmsSetting.create!(key: 'sidebar_notifications', value: 'false', fieldtype: 'Check')

      result = described_class.call

      expect(result['jobs']).to eq(1)
      expect(result['notifications']).to eq(0)
    end

    it 'returns all required sidebar fields' do
      result = described_class.call

      required_fields = [
        'courses', 'batches', 'certifications', 'jobs', 'statistics',
        'notifications', 'programming_exercises', 'my_courses', 'my_batches',
        'profile', 'settings', 'logout', 'web_pages'
      ]

      required_fields.each do |field|
        expect(result).to have_key(field)
      end
    end

    it 'handles web_pages as empty array for now' do
      result = described_class.call

      expect(result['web_pages']).to eq([])
    end
  end
end
