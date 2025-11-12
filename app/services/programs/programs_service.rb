module Programs
  class ProgramsService
    def self.call
      # Replicate exact Python implementation from lms/utils.py get_programs()

      # Get enrolled programs for current user
      enrolled_programs = get_enrolled_programs

      # Get all published programs
      published_programs = get_published_programs

      # Remove enrolled programs from published programs (as done in Python)
      enrolled_program_names = enrolled_programs.map { |p| p[:name] }
      published_programs = published_programs.reject do |program|
        enrolled_program_names.include?(program[:name])
      end

      {
        enrolled: enrolled_programs,
        published: published_programs
      }
    end

    private

    def self.get_enrolled_programs
      # Replicate: frappe.get_all("LMS Program Member", {"member": frappe.session.user}, ["parent as name", "progress"])
      return [] unless Current.user

      program_members = LmsProgramMember
        .joins(:lms_program)
        .where(user: Current.user)
        .select(
          'lms_programs.name as name',
          'lms_program_members.progress as progress'
        )

      # For each program, get additional details: frappe.db.get_value("LMS Program", program.name, ["name", "course_count", "member_count"], as_dict=True)
      program_members.map do |member|
        program = LmsProgram.find_by(name: member.name)
        next unless program

        {
          name: program.name,
          progress: member.progress.to_f,
          course_count: program.course_count || 0,
          member_count: program.member_count || 0
        }
      end.compact
    end

    def self.get_published_programs
      # Replicate: frappe.get_all("LMS Program", {"published": 1}, ["name", "course_count", "member_count"])
      LmsProgram
        .published
        .select(:name, :course_count, :member_count)
        .map do |program|
          {
            name: program.name,
            course_count: program.course_count || 0,
            member_count: program.member_count || 0
          }
        end
    end
  end
end
