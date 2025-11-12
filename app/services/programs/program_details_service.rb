module Programs
  class ProgramDetailsService
    def self.call(program_name, user = nil)
      new(program_name, user).call
    end

    def initialize(program_name, user)
      @program_name = program_name
      @user = user
    end

    def call
      program = LmsProgram.find_by(name: @program_name) || LmsProgram.find_by(id: @program_name)
      return nil unless program

      program_details = program.program_details

      # Add user-specific information if user is provided
      if @user
        membership = program.lms_program_members.find_by(user: @user)
        program_details[:membership] = membership&.to_frappe_format
        program_details[:progress] = membership&.progress || 0.0
      end

      program_details
    end
  end
end
