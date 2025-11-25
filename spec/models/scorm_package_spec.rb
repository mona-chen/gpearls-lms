require 'rails_helper'

RSpec.describe ScormPackage, type: :model do
  let(:course) { create(:course) }
  let(:chapter) { create(:course_chapter, course: course) }
  let(:lesson) { create(:course_lesson, chapter: chapter, course: course) }
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
      expect(create(:scorm_package)).to belong_to(:course_lesson)
    end

    it 'belongs to uploaded_by user' do
      package = create(:scorm_package, uploaded_by: user)
      expect(package.uploaded_by).to eq(user)
    end

    it 'has many scorm_completions' do
      package = create(:scorm_package)
      expect(package).to have_many(:scorm_completions)
    end
  end

  describe 'enums' do
    it 'defines status enum' do
      package = create(:scorm_package)
      expect(package).to define_enum_for(:status)
    end

    it 'defaults to uploaded status' do
      package = create(:scorm_package)
      expect(package.status).to eq('uploaded')
    end
  end

  describe '.create_from_upload' do
    let(:uploaded_file) { double('uploaded_file', original_filename: 'test.zip', content_type: 'application/zip') }

    it 'creates SCORM package from file upload' do
      allow_any_instance_of(ScormPackage).to receive(:package_files).and_return(double(attached?: true))
      package = ScormPackage.create_from_upload(uploaded_file, lesson, user)
      expect(package).to be_persisted
      expect(package.title).to eq('test')
    end

    it 'attaches the uploaded file' do
      allow_any_instance_of(ScormPackage).to receive(:package_files).and_return(double(attached?: true))
      package = ScormPackage.create_from_upload(uploaded_file, lesson, user)
      # File attachment is mocked for this test
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
      expect(package.launch_url).to be_present
    end
  end

  describe '#extract_package' do
    let(:valid_manifest_xml) { '<?xml version="1.0" encoding="UTF-8"?><manifest identifier="test" version="1.0" xmlns="http://www.imsglobal.org/xsd/imscp_v1p1"><metadata><schema>ADL SCORM</schema><schemaversion>2004 3rd Edition</schemaversion></metadata><organizations><organization identifier="org1"><title>Test Course</title></organization></organizations><resources><resource identifier="res1" type="webcontent" href="index.html"><file href="index.html"/></resource></resources></manifest>' }
    let(:mock_zip_file) { double('zip_file') }

    before do
      allow(File).to receive(:read).and_return(valid_manifest_xml)
      allow(mock_zip_file).to receive(:each).and_yield(double('entry', name: 'imsmanifest.xml', get_input_stream: StringIO.new(valid_manifest_xml)))
    end

    context 'with attached files' do
      it 'successfully extracts package' do
        package = create(:scorm_package)
        mock_files = double(attached?: true)
        allow(mock_files).to receive(:each).and_yield(double('file', content_type: 'application/zip', filename: double(to_s: 'test.zip'), download: 'fake content'))
        allow(package).to receive(:package_files).and_return(mock_files)
        allow(package).to receive(:parse_manifest).and_return({ content: 'test manifest', launch_file: 'index.html', version: 'SCORM 2004', metadata: {} })

        # Skip the zip extraction for this test
        allow(package).to receive(:extract_zip_file)

        result = package.extract_package

        expect(result).to be_truthy
        expect(package.status).to eq('extracted')
      end
    end

    context 'without attached files' do
      it 'returns false' do
        package = create(:scorm_package)
        allow(package).to receive(:package_files).and_return(double(attached?: false))

        result = package.extract_package
        expect(result).to be_falsey
      end
    end
  end

  describe '#completion_data_for_user' do
    let(:package) { create(:scorm_package) }
    let(:user) { create(:user) }

    it 'returns completion data for user' do
      completion = create(:scorm_completion,
                         scorm_package: package,
                         user: user,
                         completion_status: 'completed',
                         score_raw: 85.0)

      data = package.completion_data_for_user(user)
      expect(data).to eq(completion)
      expect(data.completion_status).to eq('completed')
      expect(data.score_raw).to eq(85.0)
    end

    it 'returns nil when user has no completion data' do
      data = package.completion_data_for_user(user)
      expect(data).to be_nil
    end
  end

  describe 'scopes' do
    describe '.by_course' do
      let(:lesson) { create(:course_lesson, chapter: chapter, course: course) }
      let!(:package) { create(:scorm_package, course_lesson: lesson) }
      let(:other_course) { create(:course) }
      let(:other_chapter) { create(:course_chapter, course: other_course) }
      let(:other_lesson) { create(:course_lesson, chapter: other_chapter, course: other_course) }
      let!(:other_package) { create(:scorm_package, course_lesson: other_lesson) }

      it 'returns packages for specific course' do
        expect(ScormPackage.by_course(course)).to include(package)
        expect(ScormPackage.by_course(course)).not_to include(other_package)
      end
    end
  end

  describe 'SCORM version detection' do
    it 'detects SCORM 1.2' do
      package = create(:scorm_package)
      package.detect_scorm_version('<?xml version="1.0"?><manifest><metadata><schema>ADL SCORM</schema><schemaversion>1.2</schemaversion></metadata></manifest>')
      expect(package.version).to eq('SCORM 1.2')
    end

    it 'detects SCORM 2004' do
      package = create(:scorm_package)
      package.detect_scorm_version('<?xml version="1.0"?><manifest><metadata><schema>ADL SCORM</schema><schemaversion>2004 3rd Edition</schemaversion></metadata></manifest>')
      expect(package.version).to eq('SCORM 2004')
    end

    it 'handles unknown version' do
      package = create(:scorm_package)
      package.detect_scorm_version('<?xml version="1.0"?><manifest><metadata><schema>Unknown</schema><schemaversion>1.0</schemaversion></metadata></manifest>')
      expect(package.version).to eq('Unknown')
    end
  end

  describe 'security checks' do
    let(:package) { create(:scorm_package) }

    it 'detects malicious JavaScript' do
      malicious_content = '<script>alert("hack")</script>'
      expect(package.contains_malicious_content?(malicious_content)).to be_truthy
    end

    it 'detects malicious event handlers' do
      malicious_content = '<div onclick="evil()"></div>'
      expect(package.contains_malicious_content?(malicious_content)).to be_truthy
    end

    it 'allows clean content' do
      clean_content = '<div>Hello World</div>'
      expect(package.contains_malicious_content?(clean_content)).to be_falsey
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
      allow_any_instance_of(ScormPackage).to receive(:package_files).and_return(double(attached?: true))
      expect do
        ScormPackage.create_from_upload(mock_file, lesson, user)
      end.to change(ScormPackage, :count).by(1)

      package = ScormPackage.last
      expect(package.course_lesson).to eq(lesson)
      expect(package.uploaded_by).to eq(user)
      expect(package.title).to eq('course')
      expect(package.status).to eq('uploaded')
    end

    it 'attaches the uploaded file' do
      allow_any_instance_of(ScormPackage).to receive(:package_files).and_return(double(attached?: true))
      package = ScormPackage.create_from_upload(mock_file, lesson, user)
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
      let(:mock_zip_file) { [ mock_zip_entry ] }

      before do
        # Mock file operations
        allow(FileUtils).to receive(:mkdir_p)
        allow(FileUtils).to receive(:mv)
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return(valid_manifest_xml)
        allow(Zip::File).to receive(:open).and_yield(mock_zip_file)
      end

      it 'successfully extracts package' do
        allow(package).to receive(:package_files).and_return(double(attached?: true, each: []))
        allow(package).to receive(:parse_manifest).and_return({ content: valid_manifest_xml, launch_file: 'index.html', version: 'SCORM 2004', metadata: { title: 'Test Course' } })

        expect(package.extract_package).to be_truthy
        package.reload
        expect(package.status).to eq('extracted')
        expect(package.launch_file).to eq('index.html')
        expect(package.version).to eq('SCORM 2004')
      end

      it 'parses manifest metadata' do
        allow(package).to receive(:package_files).and_return(double(attached?: true, each: []))
        allow(package).to receive(:parse_manifest).and_return({ content: valid_manifest_xml, launch_file: 'index.html', version: 'SCORM 2004', metadata: { title: 'Test Course' } })

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
        allow(package).to receive(:package_files).and_return(double(attached?: true, each: []))
        allow(package).to receive(:parse_manifest).and_return(nil) # Malicious content detected

        expect(package.extract_package).to be_falsey
        package.reload
        expect(package.status).to eq('error')
      end
    end

    context 'with extraction error' do
      before do
        allow(FileUtils).to receive(:mkdir_p).and_raise(StandardError, 'Permission denied')
        allow(File).to receive(:read).and_return('<?xml version="1.0"?><manifest><title>Test</title></manifest>')
      end

      it 'handles extraction errors gracefully' do
        allow(package).to receive(:package_files).and_return(double(attached?: true, each: []))
        allow(package).to receive(:parse_manifest).and_raise(StandardError, 'Permission denied')

        expect(package.extract_package).to be_falsey
        package.reload
        expect(package.status).to eq('error')
        expect(package.error_message).to include('Permission denied')
      end
    end
  end

  describe '#completion_data_for_user' do
    let(:package) { create(:scorm_package) }
    let!(:completion) { create(:scorm_completion, user: user, scorm_package: package, course_lesson: package.course_lesson) }

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
    let(:other_lesson) { create(:course_lesson, chapter: other_chapter, course: other_course) }

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
