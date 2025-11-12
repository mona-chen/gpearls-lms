# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Settings::LmsSettingsService, type: :service do
  describe '.call' do
    context 'with field parameter' do
      it 'returns the value for the specified field' do
        # Create a test setting
        LmsSetting.create!(
          key: 'test_setting',
          value: 'test_value',
          fieldtype: 'Data'
        )

        result = described_class.call(field: 'test_setting')
        expect(result).to eq 'test_value'
      end

      it 'returns false for non-existent field' do
        result = described_class.call(field: 'non_existent')
        expect(result).to be false
      end

      it 'returns boolean value for Check fieldtype' do
        LmsSetting.create!(
          key: 'boolean_setting',
          value: '1',
          fieldtype: 'Check'
        )

        result = described_class.call(field: 'boolean_setting')
        expect(result).to be true
      end
    end

    context 'without field parameter' do
      it 'returns all settings wrapped in message' do
        LmsSetting.create!(
          key: 'test_setting',
          value: 'test_value',
          fieldtype: 'Data'
        )

        result = described_class.call
        expect(result).to be_a(Hash)
        expect(result[:message]).to have_key(:test_setting)
        expect(result[:message][:test_setting]).to eq 'test_value'
      end

      it 'returns default settings when no database settings exist' do
        result = described_class.call
        expect(result[:message]).to have_key(:allow_guest_access)
        expect(result[:message][:allow_guest_access]).to be true
      end
    end
  end

  describe 'private methods' do
    let(:service) { described_class.new('test_field') }

    describe '#load_database_settings' do
      it 'loads settings from database' do
        LmsSetting.create!(
          key: 'db_setting',
          value: 'db_value',
          fieldtype: 'Data'
        )

        settings = service.send(:load_database_settings)
        expect(settings[:db_setting]).to eq 'db_value'
      end

      it 'returns empty hash when database has no settings' do
        settings = service.send(:load_database_settings)
        expect(settings).to eq({})
      end
    end

    describe '#default_settings' do
      it 'returns comprehensive default settings' do
        settings = service.send(:default_settings)

        expect(settings).to have_key(:allow_guest_access)
        expect(settings).to have_key(:enable_student_portal)
        expect(settings).to have_key(:enable_course_creation)
        expect(settings[:allow_guest_access]).to be true
        expect(settings[:default_language]).to eq 'en'
        expect(settings[:currency]).to eq 'USD'
      end
    end
  end
end
