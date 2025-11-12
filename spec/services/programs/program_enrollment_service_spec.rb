require 'rails_helper'

RSpec.describe Programs::ProgramEnrollmentService, type: :service do
  let(:user) { create(:user) }
  let(:program) { create(:lms_program, published: true) }
  let(:course1) { create(:course) }
  let(:course2) { create(:course) }

  before do
    create(:lms_program_course, lms_program: program, course: course1, position: 1)
    create(:lms_program_course, lms_program: program, course: course2, position: 2)
  end

  describe '.enroll_in_program' do
    context 'successful enrollment' do
      it 'creates program membership' do
        expect {
          result = described_class.enroll_in_program(program.name, user)
          expect(result[:success]).to be_truthy
        }.to change(LmsProgramMember, :count).by(1)
      end

      it 'auto-enrolls user in all program courses' do
        expect {
          described_class.enroll_in_program(program.name, user)
        }.to change(Enrollment, :count).by(2) # Two courses in program

        # Verify enrollments were created
        enrollment1 = Enrollment.find_by(user: user, course: course1)
        enrollment2 = Enrollment.find_by(user: user, course: course2)

        expect(enrollment1).to be_present
        expect(enrollment2).to be_present
        expect(enrollment1.member_type).to eq('Student')
        expect(enrollment1.role).to eq('Member')
      end

      it 'returns success response with membership data' do
        result = described_class.enroll_in_program(program.name, user)

        expect(result[:success]).to be_truthy
        expect(result[:data]).to be_a(LmsProgramMember)
        expect(result[:message]).to eq('Successfully enrolled in program')
      end

      it 'sets initial progress to 0.0' do
        result = described_class.enroll_in_program(program.name, user)

        membership = result[:data]
        expect(membership.progress).to eq(0.0)
      end
    end

    context 'validation failures' do
      it 'fails for non-existent program' do
        result = described_class.enroll_in_program('non-existent-program', user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Program not found')
      end

      it 'fails for nil user' do
        result = described_class.enroll_in_program(program.name, nil)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('User not found')
      end

      it 'fails for unpublished program' do
        program.update(published: false)
        result = described_class.enroll_in_program(program.name, user)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Program is not published')
      end

      it 'returns success for already enrolled user' do
        create(:lms_program_member, lms_program: program, user: user)

        expect {
          result = described_class.enroll_in_program(program.name, user)
          expect(result[:success]).to be_truthy
          expect(result[:message]).to eq('Already enrolled in this program')
        }.not_to change(LmsProgramMember, :count)
      end
    end

    context 'course enrollment handling' do
      it 'does not create duplicate course enrollments' do
        # Pre-enroll user in one course
        create(:enrollment, user: user, course: course1)

        expect {
          described_class.enroll_in_program(program.name, user)
        }.to change(Enrollment, :count).by(1) # Only course2 enrollment should be created

        # Verify both courses have enrollments
        expect(Enrollment.where(user: user, course: course1).count).to eq(1)
        expect(Enrollment.where(user: user, course: course2).count).to eq(1)
      end

      it 'handles programs with no courses' do
        empty_program = create(:lms_program, published: true)

        expect {
          result = described_class.enroll_in_program(empty_program.name, user)
          expect(result[:success]).to be_truthy
        }.to change(LmsProgramMember, :count).by(1)

        expect(Enrollment.count).to eq(0) # No course enrollments created
      end
    end

    context 'Frappe API compatibility' do
      it 'returns proper success response format' do
        result = described_class.enroll_in_program(program.name, user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:data)
        expect(result).to have_key(:message)
        expect(result[:success]).to be_truthy
      end

      it 'returns proper error response format' do
        result = described_class.enroll_in_program('non-existent', user)

        expect(result).to have_key(:success)
        expect(result).to have_key(:error)
        expect(result).to have_key(:message)
        expect(result[:success]).to be_falsey
      end
    end
  end
end
