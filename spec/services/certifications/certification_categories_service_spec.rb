require 'rails_helper'

RSpec.describe Certifications::CertificationCategoriesService, type: :service do
  let!(:enabled_category) { create(:certification_category, name: 'Programming', enabled: true) }
  let!(:disabled_category) { create(:certification_category, name: 'Design', enabled: false) }
  let!(:another_enabled) { create(:certification_category, name: 'Data Science', enabled: true) }

  describe '.call' do
    it 'returns only enabled categories' do
      result = described_class.call

      expect(result).to have_key('data')
      expect(result['data'].length).to eq(2)

      category_names = result['data'].map { |cat| cat['name'] }
      expect(category_names).to include('Programming', 'Data Science')
      expect(category_names).not_to include('Design')
    end

    it 'orders categories by name' do
      result = described_class.call

      names = result['data'].map { |cat| cat['name'] }
      expect(names).to eq([ 'Data Science', 'Programming' ]) # Alphabetical order
    end

    it 'returns categories in Frappe-compatible format' do
      result = described_class.call
      category_data = result['data'].first

      expected_fields = [ 'name', 'description', 'enabled', 'creation', 'modified' ]
      expected_fields.each do |field|
        expect(category_data).to have_key(field), "Missing field: #{field}"
      end
    end

    it 'includes proper timestamps' do
      result = described_class.call
      category_data = result['data'].first

      expect(category_data['creation']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      expect(category_data['modified']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
    end

    context 'when no enabled categories exist' do
      before do
        CertificationCategory.update_all(enabled: false)
      end

      it 'returns empty array' do
        result = described_class.call

        expect(result['data']).to eq([])
      end
    end

    context 'Frappe API compatibility' do
      it 'returns exact field structure matching Frappe LMS' do
        result = described_class.call
        category_data = result['data'].first

        # Verify exact field names from Frappe
        expect(category_data['name']).to eq(enabled_category.name)
        expect(category_data['enabled']).to eq(enabled_category.enabled)
      end

      it 'formats timestamps correctly' do
        result = described_class.call
        category_data = result['data'].first

        expect(category_data['creation']).to eq(enabled_category.created_at.strftime('%Y-%m-%d %H:%M:%S'))
        expect(category_data['modified']).to eq(enabled_category.updated_at.strftime('%Y-%m-%d %H:%M:%S'))
      end
    end
  end
end
