# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Settings::TranslationsService, type: :service do
  describe '.call' do
    it 'returns translations with proper structure' do
      result = described_class.call

      expect(result).to be_a(Hash)
      expect(result[:messages]).to be_a(Hash)
      expect(result[:messages]).to have_key('Login')
      expect(result[:messages]['Login']).to eq('Login')
    end

    it 'returns default translations' do
      result = described_class.call

      expect(result[:messages]['Courses']).to eq('Courses')
      expect(result[:messages]['Dashboard']).to eq('Dashboard')
      expect(result[:messages]['Certificates']).to eq('Certificates')
    end

    it 'merges custom translations from database' do
      # Create custom translation
      LmsSetting.create!(key: 'translation_Courses', value: 'Cursos', fieldtype: 'Data')
      LmsSetting.create!(key: 'translation_Login', value: 'Entrar', fieldtype: 'Data')

      result = described_class.call

      expect(result[:messages]['Courses']).to eq('Cursos')
      expect(result[:messages]['Login']).to eq('Entrar')
      # Other translations should remain default
      expect(result[:messages]['Dashboard']).to eq('Dashboard')
    end

    it 'handles database errors gracefully' do
      # Mock database error
      allow(LmsSetting).to receive(:where).and_raise(StandardError.new('DB Error'))

      result = described_class.call

      # Should still return default translations
      expect(result[:messages]['Login']).to eq('Login')
      expect(result[:messages]).to have_key('Courses')
    end

    it 'returns comprehensive translation set' do
      result = described_class.call

      expected_translations = [
        'Login', 'Logout', 'Courses', 'Batches', 'Students', 'Instructors',
        'Administrators', 'Settings', 'Profile', 'Dashboard', 'Analytics',
        'Reports', 'Certificates', 'Badges', 'Jobs', 'Notifications',
        'Messages', 'Help', 'Support', 'About', 'Contact', 'Privacy',
        'Terms', 'FAQ', 'Documentation', 'Community'
      ]

      expected_translations.each do |key|
        expect(result[:messages]).to have_key(key)
        expect(result[:messages][key]).to be_a(String)
        expect(result[:messages][key]).not_to be_empty
      end
    end
  end
end
