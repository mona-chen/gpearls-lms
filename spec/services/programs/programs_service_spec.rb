require 'rails_helper'

RSpec.describe Programs::ProgramsService, type: :service do
  let(:user) { create(:user) }
  let!(:program1) { create(:lms_program, published: true, featured: true) }
  let!(:program2) { create(:lms_program, published: true, featured: false) }
  let!(:unpublished_program) { create(:lms_program, published: false) }

  before do
    # Create program memberships for enrolled programs
    create(:lms_program_member, lms_program: program1, user: user)
  end

  describe '.call' do
    context 'without filters' do
      it 'returns enrolled and published programs separately' do
        result = described_class.call

        expect(result).to have_key(:enrolled)
        expect(result).to have_key(:published)
        expect(result[:enrolled]).to be_an(Array)
        expect(result[:published]).to be_an(Array)
      end

      it 'includes enrolled programs in enrolled section' do
        result = described_class.call

        enrolled_programs = result[:enrolled]
        expect(enrolled_programs.length).to eq(1)
        expect(enrolled_programs.first[:name]).to eq(program1.name)
        expect(enrolled_programs.first).to have_key(:progress)
        expect(enrolled_programs.first).to have_key(:course_count)
        expect(enrolled_programs.first).to have_key(:member_count)
      end

      it 'includes published programs excluding enrolled ones' do
        result = described_class.call

        published_programs = result[:published]
        expect(published_programs.length).to eq(1) # Only program2, program1 is enrolled
        expect(published_programs.first[:name]).to eq(program2.name)
        expect(published_programs.first).to have_key(:course_count)
        expect(published_programs.first).to have_key(:member_count)
      end

      it 'excludes unpublished programs' do
        result = described_class.call

        all_program_names = result[:enrolled].map { |p| p[:name] } + result[:published].map { |p| p[:name] }
        expect(all_program_names).not_to include(unpublished_program.name)
      end
    end

    context 'Frappe API compatibility' do
      it 'returns exact structure matching Frappe LMS' do
        result = described_class.call

        # Check enrolled programs structure
        enrolled_program = result[:enrolled].first
        expect(enrolled_program).to have_key(:name)
        expect(enrolled_program).to have_key(:progress)
        expect(enrolled_program).to have_key(:course_count)
        expect(enrolled_program).to have_key(:member_count)

        # Check published programs structure
        published_program = result[:published].first
        expect(published_program).to have_key(:name)
        expect(published_program).to have_key(:course_count)
        expect(published_program).to have_key(:member_count)
      end
    end
  end
end
