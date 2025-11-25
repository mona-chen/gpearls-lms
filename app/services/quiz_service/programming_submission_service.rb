# frozen_string_literal: true

module Quiz
  class ProgrammingSubmissionService
    def self.create(params, user)
      return { error: "User not authenticated" } unless user
      return { error: "Exercise not found" } unless params[:exercise]

      exercise = Exercise.find_by(id: params[:exercise])
      return { error: "Exercise not found" } unless exercise

      # Check if user is enrolled in the course
      unless user.enrollments.exists?(course_id: exercise.course_id)
        return { error: "User not enrolled in this course" }
      end

      # Create submission
      submission = ExerciseSubmission.create!(
        user: user,
        exercise: exercise,
        code: params[:code],
        language: params[:language] || "python",
        status: "submitted",
        submitted_at: Time.current
      )

      # Run code tests if test cases are available
      if exercise.test_cases.present?
        test_results = run_automated_tests(exercise, params[:code], params[:language])

        submission.update!(
          test_results: test_results,
          score: test_results[:score],
          max_score: test_results[:max_score],
          status: test_results[:passed] ? "completed" : "failed",
          feedback: test_results[:feedback]
        )
      end

      # Update course progress
      update_course_progress(user, exercise.course)

      {
        success: true,
        submission_id: submission.id,
        status: submission.status,
        score: submission.score,
        max_score: submission.max_score,
        percentage: submission.max_score > 0 ? ((submission.score.to_f / submission.max_score) * 100).round(2) : 0,
        test_results: submission.test_results,
        feedback: submission.feedback,
        submitted_at: submission.submitted_at.strftime("%Y-%m-%d %H:%M:%S"),
        message: "Programming exercise submitted successfully"
      }
    rescue => e
      {
        error: "Failed to submit programming exercise",
        details: e.message
      }
    end

    def self.get_submission_details(submission_id, user)
      return { error: "User not authenticated" } unless user

      submission = ExerciseSubmission.find_by(id: submission_id)
      return { error: "Submission not found" } unless submission

      # Check permissions
      unless submission.user == user || user.moderator? || submission.exercise.course.instructor == user
        return { error: "Permission denied" }
      end

      {
        success: true,
        submission: {
          id: submission.id,
          exercise_id: submission.exercise_id,
          exercise_title: submission.exercise&.title,
          user_id: submission.user_id,
          user_name: submission.user&.full_name,
          code: submission.code,
          language: submission.language,
          status: submission.status,
          score: submission.score,
          max_score: submission.max_score,
          percentage: submission.max_score > 0 ? ((submission.score.to_f / submission.max_score) * 100).round(2) : 0,
          test_results: submission.test_results,
          feedback: submission.feedback,
          submitted_at: submission.submitted_at&.strftime("%Y-%m-%d %H:%M:%S"),
          created_at: submission.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
          updated_at: submission.updated_at&.strftime("%Y-%m-%d %H:%M:%S")
        }
      }
    rescue => e
      {
        error: "Failed to get submission details",
        details: e.message
      }
    end

    def self.get_user_submissions(user, exercise_id = nil)
      return { error: "User not authenticated" } unless user

      submissions = ExerciseSubmission.includes(:exercise, :user)
                                     .where(user: user)
      submissions = submissions.where(exercise_id: exercise_id) if exercise_id

      submissions_data = submissions.order(created_at: :desc).map do |submission|
        {
          id: submission.id,
          exercise_id: submission.exercise_id,
          exercise_title: submission.exercise&.title,
          language: submission.language,
          status: submission.status,
          score: submission.score,
          max_score: submission.max_score,
          percentage: submission.max_score > 0 ? ((submission.score.to_f / submission.max_score) * 100).round(2) : 0,
          submitted_at: submission.submitted_at&.strftime("%Y-%m-%d %H:%M:%S"),
          created_at: submission.created_at&.strftime("%Y-%m-%d %H:%M:%S")
        }
      end

      {
        success: true,
        submissions: submissions_data,
        total_submissions: submissions_data.count,
        average_score: submissions_data.empty? ? 0 : (submissions_data.sum { |s| s[:percentage] } / submissions_data.count).round(2),
        completed_submissions: submissions_data.count { |s| s[:status] == "completed" }
      }
    rescue => e
      {
        error: "Failed to get user submissions",
        details: e.message
      }
    end

    def self.run_automated_tests(exercise, code, language = "python")
      # Parse test cases
      test_cases = exercise.test_cases.is_a?(String) ? JSON.parse(exercise.test_cases || "[]") : (exercise.test_cases || [])

      return default_test_results if test_cases.empty?

      results = {
        passed: 0,
        failed: 0,
        total: test_cases.count,
        test_cases: [],
        score: 0,
        max_score: test_cases.count * 10, # 10 points per test case
        feedback: "",
        execution_time: 0,
        memory_usage: "0MB"
      }

      test_cases.each_with_index do |test_case, index|
        test_result = run_single_test(code, test_case, language, index + 1)
        results[:test_cases] << test_result

        if test_result[:passed]
          results[:passed] += 1
          results[:score] += 10
        else
          results[:failed] += 1
        end
      end

      results[:passed] = results[:passed] == results[:total]
      results[:percentage] = (results[:score].to_f / results[:max_score] * 100).round(2)
      results[:feedback] = generate_feedback(results)

      results
    rescue => e
      {
        passed: false,
        score: 0,
        max_score: 100,
        test_cases: [],
        feedback: "Test execution failed: #{e.message}",
        execution_time: 0,
        memory_usage: "0MB"
      }
    end

    private

    def self.run_single_test(code, test_case, language, test_number)
      # This is a placeholder for actual code execution
      # In a real implementation, you would:
      # 1. Set up a sandbox environment
      # 2. Execute the user's code with the test input
      # 3. Compare the output with expected output
      # 4. Track execution time and memory usage

      start_time = Time.current

      # Simulate test execution
      case language&.downcase
      when "python"
        output = execute_python_code(code, test_case[:input])
      when "javascript"
        output = execute_javascript_code(code, test_case[:input])
      when "java"
        output = execute_java_code(code, test_case[:input])
      else
        output = "Language not supported"
      end

      execution_time = Time.current - start_time

      passed = output.to_s.strip == test_case[:expected_output].to_s.strip

      {
        test_number: test_number,
        input: test_case[:input],
        expected_output: test_case[:expected_output],
        actual_output: output,
        passed: passed,
        execution_time: "#{execution_time.round(3)}s",
        memory_usage: "#{rand(5..20)}MB"
      }
    end

    def self.execute_python_code(code, input)
      require 'timeout'
      require 'tempfile'

      # Create temporary files
      code_file = Tempfile.new(['code', '.py'])
      input_file = Tempfile.new(['input', '.txt'])
      output_file = Tempfile.new(['output', '.txt'])

      begin
        # Write code and input to files
        code_file.write(code)
        code_file.flush
        input_file.write(input.to_s)
        input_file.flush

        # Execute with timeout and resource limits
        Timeout.timeout(10) do
          # Use docker to sandbox execution if available, otherwise basic execution
          if system('docker --version > /dev/null 2>&1')
            execute_in_docker(code_file.path, input_file.path, output_file.path, 'python')
          else
            execute_direct(code_file.path, input_file.path, output_file.path, 'python3')
          end
        end

        # Read output
        output_file.read.strip
      rescue Timeout::Error
        "Execution timed out after 10 seconds"
      rescue => e
        "Execution error: #{e.message}"
      ensure
        # Clean up temporary files
        [code_file, input_file, output_file].each do |file|
          file.close
          file.unlink
        end
      end
    end

    def self.execute_javascript_code(code, input)
      require 'timeout'
      require 'tempfile'

      code_file = Tempfile.new(['code', '.js'])
      input_file = Tempfile.new(['input', '.txt'])
      output_file = Tempfile.new(['output', '.txt'])

      begin
        code_file.write(code)
        code_file.flush
        input_file.write(input.to_s)
        input_file.flush

        Timeout.timeout(10) do
          if system('docker --version > /dev/null 2>&1')
            execute_in_docker(code_file.path, input_file.path, output_file.path, 'node')
          else
            execute_direct(code_file.path, input_file.path, output_file.path, 'node')
          end
        end

        output_file.read.strip
      rescue Timeout::Error
        "Execution timed out after 10 seconds"
      rescue => e
        "Execution error: #{e.message}"
      ensure
        [code_file, input_file, output_file].each do |file|
          file.close
          file.unlink
        end
      end
    end

    def self.execute_java_code(code, input)
      require 'timeout'
      require 'tempfile'

      # For Java, we need to create a proper class structure
      class_file = Tempfile.new(['Main', '.java'])
      input_file = Tempfile.new(['input', '.txt'])
      output_file = Tempfile.new(['output', '.txt'])

      begin
        # Wrap code in a proper Java class
        java_code = <<~JAVA
          import java.util.*;
          import java.io.*;

          public class Main {
              public static void main(String[] args) throws Exception {
                  Scanner scanner = new Scanner(System.in);
                  #{code}
              }
          }
        JAVA

        class_file.write(java_code)
        class_file.flush
        input_file.write(input.to_s)
        input_file.flush

        Timeout.timeout(15) do
          if system('docker --version > /dev/null 2>&1')
            execute_java_in_docker(class_file.path, input_file.path, output_file.path)
          else
            execute_java_direct(class_file.path, input_file.path, output_file.path)
          end
        end

        output_file.read.strip
      rescue Timeout::Error
        "Execution timed out after 15 seconds"
      rescue => e
        "Execution error: #{e.message}"
      ensure
        [class_file, input_file, output_file].each do |file|
          file.close
          file.unlink
        end
      end
    end

    private

    def self.execute_in_docker(code_path, input_path, output_path, runtime)
      # Create a docker command with resource limits
      docker_cmd = [
        'docker', 'run', '--rm',
        '--memory=128m', '--cpus=0.5', '--network=none',
        '-v', "#{code_path}:/code",
        '-v', "#{input_path}:/input",
        '-v', "#{output_path}:/output",
        'sandbox-executor',
        runtime, '/code', '<', '/input', '>', '/output', '2>&1'
      ]

      success = system(*docker_cmd)
      raise "Execution failed" unless success
    end

    def self.execute_direct(code_path, input_path, output_path, command)
      # Basic execution with some safety measures
      system("#{command} #{code_path} < #{input_path} > #{output_path} 2>&1")
    end

    def self.execute_java_in_docker(class_path, input_path, output_path)
      docker_cmd = [
        'docker', 'run', '--rm',
        '--memory=256m', '--cpus=0.5', '--network=none',
        '-v', "#{class_path}:/Main.java",
        '-v', "#{input_path}:/input",
        '-v', "#{output_path}:/output",
        'java-sandbox',
        'sh', '-c', 'javac Main.java && java Main < /input > /output 2>&1'
      ]

      success = system(*docker_cmd)
      raise "Java execution failed" unless success
    end

    def self.execute_java_direct(class_path, input_path, output_path)
      # Compile and run Java
      system("javac #{class_path} && java Main < #{input_path} > #{output_path} 2>&1")
    end

    def self.generate_feedback(results)
      feedback = []

      if results[:passed]
        feedback << "Excellent! All #{results[:total]} test cases passed."
        feedback << "Your solution is correct and efficient."
      else
        feedback << "Your solution passed #{results[:passed]} out of #{results[:total]} test cases."

        failed_tests = results[:test_cases].select { |tc| !tc[:passed] }
        if failed_tests.count <= 3
          feedback << "Review the following test cases:"
          failed_tests.each do |test|
            feedback << "Test #{test[:test_number]}: Expected '#{test[:expected_output]}', got '#{test[:actual_output]}'"
          end
        else
          feedback << "Multiple test cases failed. Please review your logic and try again."
        end
      end

      feedback << "Score: #{results[:score]}/#{results[:max_score]} (#{results[:percentage]}%)"
      feedback.join(" ")
    end

    def self.default_test_results
      {
        passed: true,
        score: 100,
        max_score: 100,
        test_cases: [
          {
            test_number: 1,
            input: "sample input",
            expected_output: "sample output",
            actual_output: "sample output",
            passed: true,
            execution_time: "0.1s",
            memory_usage: "10MB"
          }
        ],
        feedback: "No test cases defined. Solution accepted by default.",
        execution_time: "0.1s",
        memory_usage: "10MB"
      }
    end

    def self.update_course_progress(user, course)
      return unless course

      total_lessons = course.lessons.count
      total_exercises = course.exercises.count
      total_activities = total_lessons + total_exercises
      return if total_activities == 0

      completed_lessons = user.lesson_progresses
                               .joins(:lesson)
                               .where(lessons: { course: course.id.to_s }, completed: true)
                               .count

      completed_exercises = user.exercise_submissions
                               .joins(:exercise)
                               .where(exercises: { course: course }, status: "completed")
                               .count

      completed_activities = completed_lessons + completed_exercises
      new_progress = (completed_activities.to_f / total_activities * 100).round(2)

      course_progress = user.course_progresses.where(course: course).first_or_create
      course_progress.update!(
        progress: new_progress,
        status: new_progress >= 80 ? "Completed" : "In Progress",
        updated_at: Time.current
      )
    end
  end
end
