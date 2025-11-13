class ScormPackage < ApplicationRecord
  belongs_to :course_lesson
  belongs_to :uploaded_by, class_name: 'User'
  
  has_many_attached :package_files
  
  validates :title, presence: true
  validates :manifest_file, presence: true
  validates :launch_file, presence: true
  validates :version, presence: true
  
  enum status: { uploaded: 0, extracting: 1, extracted: 2, error: 3 }
  
  scope :by_course, ->(course) { joins(:course_lesson).where(course_lessons: { course: course }) }
  
  after_create :extract_package_async
  
  def extract_package
    return false unless package_files.attached?
    
    update!(status: :extracting)
    
    begin
      # Create extraction directory
      extraction_path = Rails.root.join('tmp', 'scorm_extractions', id.to_s)
      FileUtils.mkdir_p(extraction_path)
      
      # Download and extract package
      package_files.each do |file|
        if file.content_type == 'application/zip'
          extract_zip_file(file, extraction_path)
        else
          # Handle individual files
          File.open(extraction_path.join(file.filename.to_s), 'wb') do |f|
            f.write(file.download)
          end
        end
      end
      
      # Parse manifest
      manifest_data = parse_manifest(extraction_path)
      
      if manifest_data
        update!(
          status: :extracted,
          manifest_content: manifest_data[:content],
          launch_file: manifest_data[:launch_file],
          version: manifest_data[:version],
          extracted_path: extraction_path.to_s,
          metadata: manifest_data[:metadata]
        )
        
        # Move files to permanent location
        move_to_permanent_location(extraction_path)
        
        true
      else
        update!(status: :error, error_message: "Invalid SCORM manifest")
        false
      end
    rescue => e
      Rails.logger.error "SCORM extraction error: #{e.message}"
      update!(status: :error, error_message: e.message)
      false
    end
  end
  
  def launch_url
    return nil unless extracted? && launch_file.present?
    
    "/scorm_packages/#{id}/#{launch_file}"
  end
  
  def self.create_from_upload(lesson, file, user)
    package = create!(
      course_lesson: lesson,
      uploaded_by: user,
      title: File.basename(file.original_filename, '.*'),
      status: :uploaded
    )
    
    package.package_files.attach(file)
    package
  end
  
  def completion_data_for_user(user)
    # This would integrate with SCORM API tracking
    scorm_completions.find_by(user: user)
  end
  
  private
  
  def extract_package_async
    ScormExtractionJob.perform_later(self)
  end
  
  def extract_zip_file(file, extraction_path)
    # Download file to temporary location
    temp_file = Tempfile.new(['scorm_package', '.zip'])
    temp_file.binmode
    temp_file.write(file.download)
    temp_file.close
    
    # Extract using rubyzip
    Zip::File.open(temp_file.path) do |zip_file|
      zip_file.each do |entry|
        # Check for malicious paths
        next if entry.name.include?('..')
        
        file_path = extraction_path.join(entry.name)
        
        # Create directory if needed
        FileUtils.mkdir_p(File.dirname(file_path))
        
        # Extract file
        entry.extract(file_path) unless File.exist?(file_path)
      end
    end
  ensure
    temp_file&.unlink
  end
  
  def parse_manifest(extraction_path)
    manifest_path = extraction_path.join('imsmanifest.xml')
    
    return nil unless File.exist?(manifest_path)
    
    begin
      doc = Nokogiri::XML(File.read(manifest_path))
      
      # Check for malicious content
      return nil if check_for_malicious_code(doc)
      
      # Extract metadata
      metadata = extract_manifest_metadata(doc)
      
      # Find launch file
      launch_file = find_launch_file(doc)
      
      # Determine SCORM version
      version = determine_scorm_version(doc)
      
      {
        content: doc.to_xml,
        launch_file: launch_file,
        version: version,
        metadata: metadata
      }
    rescue Nokogiri::XML::SyntaxError => e
      Rails.logger.error "Manifest parsing error: #{e.message}"
      nil
    end
  end
  
  def check_for_malicious_code(doc)
    # Check for potentially malicious content
    malicious_patterns = [
      /<script[^>]*>/i,
      /javascript:/i,
      /vbscript:/i,
      /onload\s*=/i,
      /onclick\s*=/i
    ]
    
    xml_string = doc.to_xml
    malicious_patterns.any? { |pattern| xml_string.match?(pattern) }
  end
  
  def extract_manifest_metadata(doc)
    metadata = {}
    
    # Extract title
    title_node = doc.at_xpath('//xmlns:title')
    metadata[:title] = title_node&.text
    
    # Extract description
    desc_node = doc.at_xpath('//xmlns:description')
    metadata[:description] = desc_node&.text
    
    # Extract learning objectives
    objectives = doc.xpath('//xmlns:learningobjective').map(&:text)
    metadata[:objectives] = objectives if objectives.any?
    
    # Extract duration
    duration_node = doc.at_xpath('//xmlns:typicallearningtime')
    metadata[:duration] = duration_node&.text
    
    metadata
  end
  
  def find_launch_file(doc)
    # Look for the main launch file
    resource = doc.at_xpath('//xmlns:resource[@type="webcontent"][@href]')
    resource&.attribute('href')&.value
  end
  
  def determine_scorm_version(doc)
    # Check SCORM version based on manifest structure
    if doc.at_xpath('//xmlns:schemaversion[contains(text(), "2004")]')
      'SCORM 2004'
    elsif doc.at_xpath('//xmlns:schemaversion[contains(text(), "1.2")]')
      'SCORM 1.2'
    else
      'Unknown'
    end
  end
  
  def move_to_permanent_location(temp_path)
    permanent_path = Rails.root.join('public', 'scorm_packages', id.to_s)
    
    FileUtils.mkdir_p(File.dirname(permanent_path))
    FileUtils.mv(temp_path, permanent_path)
    
    update_column(:extracted_path, permanent_path.to_s)
  end
end