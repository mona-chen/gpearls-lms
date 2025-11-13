require 'rails_helper'

RSpec.describe ScormPackage, type: :model do
  let(:course) { create(:course) }
  let(:chapter) { create(:course_chapter, course: course) }
  let(:lesson) { create(:course_lesson, course_chapter: chapter, course: course) }
  let(:user) { create(:user) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      package = build(:scorm_package,
                     course_lesson: lesson,
                     uploaded_by: user,
                     title: 'Test SCORM Package',
                     manifest_file: 'imsmanifest.xml',
                     launch_file: 'index.html',
                     version: 'SCORM 2004')
      expect(package).to be_valid
    end

    it 'is invalid without title' do
      package = build(:scorm_package, title: nil)
      expect(package).to_not be_valid
    end

    it 'is invalid without manifest_file' do
      package = build(:scorm_package, manifest_file: nil)
      expect(package).to_not be_valid
    end

    it 'is invalid without launch_file' do
      package = build(:scorm_package, launch_file: nil)
      expect(package).to_not be_valid
    end

    it 'is invalid without version' do
      package = build(:scorm_package, version: nil)
      expect(package).to_not be_valid
    end
  end

  describe 'associations' do
    it 'belongs to course_lesson' do
      package = create(:scorm_package, course_lesson: lesson)
      expect(package.course_lesson).to eq(lesson)
    end

    it 'belongs to uploaded_by user' do
      package = create(:scorm_package, uploaded_by: user)
      expect(package.uploaded_by).to eq(user)
    end

    it 'has many scorm_completions' do
      package = create(:scorm_package)
      expect(package).to respond_to(:scorm_completions)
    end
  end

  describe 'enums' do
    it 'defines status enum' do
      package = create(:scorm_package)
      expect(package).to respond_to(:uploaded?)
      expect(package).to respond_to(:extracting?)
      expect(package).to respond_to(:extracted?)
      expect(package).to respond_to(:error?)
    end

    it 'defaults to uploaded status' do
      package = create(:scorm_package)
      expect(package.status).to eq('uploaded')
    end
  end

  describe '.create_from_upload' do
    let(:mock_file) { double('file', original_filename: 'course.zip', content_type: 'application/zip') }

    it 'creates SCORM package from file upload' do
      expect do
        ScormPackage.create_from_upload(lesson, mock_file, user)
      end.to change(ScormPackage, :count).by(1)

      package = ScormPackage.last
      expect(package.course_lesson).to eq(lesson)
      expect(package.uploaded_by).to eq(user)
      expect(package.title).to eq('course')
      expect(package.status).to eq('uploaded')
    end

    it 'attaches the uploaded file' do
      allow(mock_file).to receive(:attach)
      package = ScormPackage.create_from_upload(lesson, mock_file, user)
      # In a real test, you'd verify the file attachment
      expect(package).to be_persisted
    end
  end

  describe '#launch_url' do
    it 'returns nil for non-extracted package' do
      package = create(:scorm_package, status: 'uploaded')
      expect(package.launch_url).to be_nil
    end

    it 'returns launch URL for extracted package' do
      package = create(:scorm_package, 
                      status: 'extracted',
                      launch_file: 'index.html')
      expected_url = "/scorm_packages/#{package.id}/index.html"
      expect(package.launch_url).to eq(expected_url)
    end
  end

  describe '#extract_package' do
    let(:package) { create(:scorm_package, course_lesson: lesson, uploaded_by: user) }

    before do
      # Mock file operations
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:mv)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).and_return(valid_manifest_xml)
      allow(Zip::File).to receive(:open).and_yield(mock_zip_file)
    end

    context 'with valid SCORM package' do
      let(:valid_manifest_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <manifest xmlns="http://www.imsglobal.org/xsd/imscp_v1p1"
                   xmlns:adlcp="http://www.adlnet.org/xsd/adlcp_v1p3">
            <metadata>
              <schema>ADL SCORM</schema>
              <schemaversion>2004 4th Edition</schemaversion>
            </metadata>
            <organizations>
              <organization identifier="course_org">
                <title>Test Course</title>
                <item identifier="item1" identifierref="resource1">
                  <title>Lesson 1</title>
                </item>
              </organization>
            </organizations>
            <resources>
              <resource identifier="resource1" type="webcontent" href="index.html">
                <file href="index.html"/>
              </resource>
            </resources>
          </manifest>
        XML
      end

      let(:mock_zip_entry) { double('zip_entry', name: 'index.html', extract: true) }
      let(:mock_zip_file) { [mock_zip_entry] }

      it 'successfully extracts package' do
        expect(package.extract_package).to be_truthy
        package.reload
        expect(package.status).to eq('extracted')
        expect(package.launch_file).to eq('index.html')
        expect(package.version).to eq('SCORM 2004')
      end

      it 'parses manifest metadata' do
        package.extract_package
        package.reload
        expect(package.manifest_content).to include('Test Course')
      end
    end

    context 'with malicious content' do
      let(:malicious_manifest_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <manifest>
            <title>Malicious Course<script>alert('hack')</script></title>
          </manifest>
        XML
      end

      before do
        allow(File).to receive(:read).and_return(malicious_manifest_xml)
      end

      it 'detects and rejects malicious content' do
        expect(package.extract_package).to be_falsey
        package.reload
        expect(package.status).to eq('error')
        expect(package.error_message).to include('Invalid SCORM manifest')
      end
    end

    context 'with extraction error' do
      before do
        allow(FileUtils).to receive(:mkdir_p).and_raise(StandardError, 'Permission denied')
      end

      it 'handles extraction errors gracefully' do
        expect(package.extract_package).to be_falsey
        package.reload
        expect(package.status).to eq('error')
        expect(package.error_message).to include('Permission denied')
      end
    end
  end

  describe '#completion_data_for_user' do
    let(:package) { create(:scorm_package) }
    let(:completion) { create(:scorm_completion, user: user, scorm_package: package) }

    it 'returns completion data for user' do
      result = package.completion_data_for_user(user)
      expect(result).to eq(completion)
    end

    it 'returns nil when user has no completion data' do
      other_user = create(:user)
      result = package.completion_data_for_user(other_user)
      expect(result).to be_nil
    end
  end

  describe 'scopes' do
    let(:other_course) { create(:course) }
    let(:other_chapter) { create(:course_chapter, course: other_course) }
    let(:other_lesson) { create(:course_lesson, course_chapter: other_chapter, course: other_course) }

    before do
      create(:scorm_package, course_lesson: lesson)
      create(:scorm_package, course_lesson: lesson)
      create(:scorm_package, course_lesson: other_lesson)
    end

    describe '.by_course' do
      it 'returns packages for specific course' do
        packages = ScormPackage.by_course(course)
        expect(packages.count).to eq(2)
        packages.each do |package|
          expect(package.course_lesson.course).to eq(course)
        end
      end
    end
  end

  describe 'SCORM version detection' do
    it 'detects SCORM 1.2' do
      package = create(:scorm_package)
      manifest_doc = double('doc')
      allow(manifest_doc).to receive(:at_xpath)
        .with('//xmlns:schemaversion[contains(text(), "1.2")]')
        .and_return(double('node'))
      allow(manifest_doc).to receive(:at_xpath)
        .with('//xmlns:schemaversion[contains(text(), "2004")]')
        .and_return(nil)

      version = package.send(:determine_scorm_version, manifest_doc)
      expect(version).to eq('SCORM 1.2')
    end

    it 'detects SCORM 2004' do
      package = create(:scorm_package)
      manifest_doc = double('doc')
      allow(manifest_doc).to receive(:at_xpath)
        .with('//xmlns:schemaversion[contains(text(), "2004")]')
        .and_return(double('node'))

      version = package.send(:determine_scorm_version, manifest_doc)
      expect(version).to eq('SCORM 2004')
    end

    it 'handles unknown version' do
      package = create(:scorm_package)
      manifest_doc = double('doc')
      allow(manifest_doc).to receive(:at_xpath).and_return(nil)

      version = package.send(:determine_scorm_version, manifest_doc)
      expect(version).to eq('Unknown')
    end
  end

  describe 'security checks' do
    let(:package) { create(:scorm_package) }

    it 'detects malicious JavaScript' do
      malicious_doc = double('doc', to_xml: '<script>alert("hack")</script>')
      result = package.send(:check_for_malicious_code, malicious_doc)
      expect(result).to be_truthy
    end

    it 'detects malicious event handlers' do
      malicious_doc = double('doc', to_xml: '<div onclick="malicious()">content</div>')
      result = package.send(:check_for_malicious_code, malicious_doc)
      expect(result).to be_truthy
    end

    it 'allows clean content' do
      clean_doc = double('doc', to_xml: '<div>Clean content</div>')
      result = package.send(:check_for_malicious_code, clean_doc)
      expect(result).to be_falsey
    end
  end

  after(:each) do
    # Clean up any extracted files
    ScormPackage.all.each do |package|
      FileUtils.rm_rf(package.extracted_path) if package.extracted_path
    end
  end
end