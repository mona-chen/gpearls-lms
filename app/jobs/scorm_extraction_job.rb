class ScormExtractionJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(scorm_package)
    Rails.logger.info "Starting SCORM extraction for package #{scorm_package.id}"

    begin
      success = scorm_package.extract_package

      if success
        Rails.logger.info "Successfully extracted SCORM package #{scorm_package.id}"

        # Notify relevant users about successful extraction
        notify_extraction_success(scorm_package)

        # Update lesson with SCORM content if needed
        update_lesson_content(scorm_package)
      else
        Rails.logger.error "Failed to extract SCORM package #{scorm_package.id}: #{scorm_package.error_message}"
        notify_extraction_failure(scorm_package)
      end

    rescue => e
      Rails.logger.error "SCORM extraction job failed for package #{scorm_package.id}: #{e.message}"
      scorm_package.update!(status: :error, error_message: e.message)
      notify_extraction_failure(scorm_package, e.message)
      raise e
    end
  end

  private

  def notify_extraction_success(package)
    # Send notification to the user who uploaded the package
    NotificationService.create_notification(
      user: package.uploaded_by,
      title: "SCORM Package Extracted",
      message: "Your SCORM package '#{package.title}' has been successfully processed and is ready for use.",
      notification_type: "scorm_extraction_success",
      related_object: package
    )

    # Notify course instructors
    package.course_lesson.course.instructors.each do |instructor|
      NotificationService.create_notification(
        user: instructor,
        title: "New SCORM Content Available",
        message: "SCORM package '#{package.title}' has been added to lesson '#{package.course_lesson.title}'.",
        notification_type: "scorm_content_added",
        related_object: package
      )
    end
  end

  def notify_extraction_failure(package, error_message = nil)
    message = "Failed to process SCORM package '#{package.title}'"
    message += ": #{error_message}" if error_message

    NotificationService.create_notification(
      user: package.uploaded_by,
      title: "SCORM Package Processing Failed",
      message: message,
      notification_type: "scorm_extraction_error",
      related_object: package
    )
  end

  def update_lesson_content(package)
    lesson = package.course_lesson

    # Update lesson to include SCORM launch information
    lesson.update!(
      content_type: "scorm",
      scorm_package: package,
      body: generate_scorm_content_html(package)
    )
  end

  def generate_scorm_content_html(package)
    <<~HTML
      <div class="scorm-content">
        <h3>#{package.title}</h3>
        #{package.metadata&.dig('description') ? "<p>#{package.metadata['description']}</p>" : ''}
      #{'  '}
        <div class="scorm-launch-container">
          <iframe#{' '}
            src="#{package.launch_url}"#{' '}
            width="100%"#{' '}
            height="600"
            frameborder="0"
            class="scorm-player"
            id="scorm-player-#{package.id}">
          </iframe>
        </div>
      #{'  '}
        <div class="scorm-info">
          <p><strong>SCORM Version:</strong> #{package.version}</p>
          #{package.metadata&.dig('duration') ? "<p><strong>Estimated Duration:</strong> #{package.metadata['duration']}</p>" : ''}
          #{package.metadata&.dig('objectives') ? "<p><strong>Learning Objectives:</strong></p><ul>#{package.metadata['objectives'].map { |obj| "<li>#{obj}</li>" }.join}</ul>" : ''}
        </div>
      </div>

      <script>
        // SCORM API integration
        window.API = {
          Initialize: function() { return "true"; },
          Terminate: function() { return "true"; },
          GetValue: function(element) {#{' '}
            return ScormTracking.getValue(element, #{package.id});#{' '}
          },
          SetValue: function(element, value) {#{' '}
            return ScormTracking.setValue(element, value, #{package.id});#{' '}
          },
          Commit: function() {#{' '}
            return ScormTracking.commit(#{package.id});#{' '}
          },
          GetLastError: function() { return "0"; },
          GetErrorString: function(errorCode) { return ""; },
          GetDiagnostic: function(errorCode) { return ""; }
        };
      #{'  '}
        // Also provide API_1484_11 for SCORM 2004
        window.API_1484_11 = window.API;
      </script>
    HTML
  end
end
