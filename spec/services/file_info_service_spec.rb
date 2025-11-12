require 'rails_helper'

RSpec.describe FileInfoService, type: :service do
  describe '.call' do
    context 'with valid file URL for existing LmsFile' do
      let!(:lms_file) { create(:lms_file, file_name: 'test.pdf', file_url: '/uploads/files/test.pdf', file_size: 1024) }

      it 'returns file information' do
        result = described_class.call('/uploads/files/test.pdf')

        expect(result).to include(
          file_name: 'test.pdf',
          file_url: '/uploads/files/test.pdf',
          file_size: 1024
        )
        expect(result).to have_key(:file_type)
        expect(result).to have_key(:is_private)
      end
    end

    context 'with file URL for non-existent LmsFile but existing file on disk' do
      before do
        # Create a temporary file
        file_path = Rails.root.join('public', 'uploads', 'files', 'temp.txt')
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, 'test content')
      end

      after do
        # Clean up
        file_path = Rails.root.join('public', 'uploads', 'files', 'temp.txt')
        File.delete(file_path) if File.exist?(file_path)
      end

      it 'returns file information from file system' do
        result = described_class.call('/uploads/files/temp.txt')

        expect(result).to include(
          file_name: 'temp.txt',
          file_url: '/uploads/files/temp.txt'
        )
        expect(result[:file_type]).to eq('text/plain')
        expect(result[:file_size]).to eq(12) # "test content" is 12 bytes
      end
    end

    context 'with non-existent file URL' do
      it 'returns error' do
        result = described_class.call('/uploads/files/nonexistent.pdf')

        expect(result).to eq({ error: 'File not found' })
      end
    end

    context 'with empty file URL' do
      it 'returns error' do
        result = described_class.call('')

        expect(result).to eq({ error: 'File URL required' })
      end
    end

    context 'with nil file URL' do
      it 'returns error' do
        result = described_class.call(nil)

        expect(result).to eq({ error: 'File URL required' })
      end
    end
  end
end
