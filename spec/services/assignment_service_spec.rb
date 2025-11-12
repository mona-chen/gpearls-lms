require 'rails_helper'

RSpec.describe AssignmentService, type: :service do
  let(:user) { create(:user) }
  let(:course) { create(:course, :published) }
  let(:assignment) { create(:lms_assignment, course: course) }
  let(:enrollment) { create(:enrollment, user: user, course: course) }

  describe '.upload' do
    let(:file) { fixture_file_upload('test.pdf', 'application/pdf') }

    before do
      allow(LmsFile).to receive(:max_file_size).and_return(10.megabytes)
      allow(LmsFile).to receive(:allowed_file_types).and_return([ 'application/pdf' ])
    end

    context 'with valid parameters' do
      before do
        enrollment # ensure enrollment exists
      end

      it 'uploads file successfully' do
        allow(System::FileUploadService).to receive(:process_upload).and_return({
          success: true,
          file_url: '/uploads/files/test.pdf',
          file_name: 'test.pdf',
          file_type: 'application/pdf',
          file_size: 1024
        })

        result = described_class.upload({
          assignment: assignment.title,
          file: file
        }, user)

        expect(result[:success]).to be true
        expect(result[:message]).to eq('File uploaded successfully')
        expect(result[:data]).to include(:file_id, :file_url, :file_name, :submission_id)
      end

      it 'creates LmsFile record' do
        allow(System::FileUploadService).to receive(:process_upload).and_return({
          success: true,
          file_url: '/uploads/files/test.pdf',
          file_name: 'test.pdf',
          file_type: 'application/pdf',
          file_size: 1024
        })

        expect {
          described_class.upload({
            assignment: assignment.title,
            file: file
          }, user)
        }.to change(LmsFile, :count).by(1)

        lms_file = LmsFile.last
        expect(lms_file.file_name).to eq('test.pdf')
        expect(lms_file.attached_to_doctype).to eq('LMS Assignment Submission')
        expect(lms_file.is_private).to be true
      end

      it 'creates or updates assignment submission' do
        allow(System::FileUploadService).to receive(:process_upload).and_return({
          success: true,
          file_url: '/uploads/files/test.pdf',
          file_name: 'test.pdf',
          file_type: 'application/pdf',
          file_size: 1024
        })

        expect {
          described_class.upload({
            assignment: assignment.title,
            file: file
          }, user)
        }.to change(AssignmentSubmission, :count).by(1)

        submission = AssignmentSubmission.last
        expect(submission.user).to eq(user)
        expect(submission.assignment).to eq(assignment)
        expect(submission.status).to eq('submitted')
        expect(submission.submitted_at).to be_present
      end
    end

    context 'without assignment' do
      it 'returns error' do
        result = described_class.upload({ file: file }, user)

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Assignment name required')
      end
    end

    context 'without file' do
      it 'returns error' do
        result = described_class.upload({ assignment: assignment.title }, user)

        expect(result[:success]).to be false
        expect(result[:message]).to eq('File required')
      end
    end

    context 'with non-existent assignment' do
      it 'returns error' do
        result = described_class.upload({
          assignment: 'Non-existent Assignment',
          file: file
        }, user)

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Assignment not found')
      end
    end

    context 'with user not enrolled in course' do
      it 'returns error' do
        # Don't create enrollment
        result = described_class.upload({
          assignment: assignment.title,
          file: file
        }, user)

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Not enrolled in course')
      end
    end

    context 'with file upload failure' do
      before do
        enrollment # ensure enrollment exists
      end

      it 'returns error' do
        allow(System::FileUploadService).to receive(:process_upload).and_return({
          success: false,
          error: 'Upload failed'
        })

        result = described_class.upload({
          assignment: assignment.title,
          file: file
        }, user)

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Upload failed')
      end
    end
  end
end
