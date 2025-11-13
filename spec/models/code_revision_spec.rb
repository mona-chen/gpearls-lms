require 'rails_helper'

RSpec.describe CodeRevision, type: :model do
  let(:user) { create(:user) }
  let(:exercise) { create(:lms_programming_exercise) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      revision = build(:code_revision,
                      user: user,
                      section_id: exercise.id,
                      section_type: 'LmsProgrammingExercise',
                      code: 'print("Hello World")')
      expect(revision).to be_valid
    end

    it 'is invalid without code' do
      revision = build(:code_revision, code: nil)
      expect(revision).to_not be_valid
    end

    it 'is invalid without section_id' do
      revision = build(:code_revision, section_id: nil)
      expect(revision).to_not be_valid
    end

    it 'is invalid without user' do
      revision = build(:code_revision, user: nil)
      expect(revision).to_not be_valid
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      revision = create(:code_revision, user: user)
      expect(revision.user).to eq(user)
    end

    it 'has polymorphic association to exercise_section' do
      revision = create(:code_revision,
                       section_id: exercise.id,
                       section_type: 'LmsProgrammingExercise')
      expect(revision.section_id).to eq(exercise.id.to_s)
      expect(revision.section_type).to eq('LmsProgrammingExercise')
    end
  end

  describe '.autosave_for_section' do
    it 'creates a new code revision' do
      expect do
        CodeRevision.autosave_for_section(
          exercise.id,
          'LmsProgrammingExercise',
          'print("Auto saved code")',
          user
        )
      end.to change(CodeRevision, :count).by(1)

      revision = CodeRevision.last
      expect(revision.user).to eq(user)
      expect(revision.section_id).to eq(exercise.id.to_s)
      expect(revision.section_type).to eq('LmsProgrammingExercise')
      expect(revision.code).to eq('print("Auto saved code")')
    end

    it 'matches Frappe autosave_section API behavior' do
      revision = CodeRevision.autosave_for_section(
        exercise.id,
        'LmsProgrammingExercise',
        'def solve(): return 42',
        user
      )
      
      expect(revision).to be_persisted
      expect(revision.id).to be_present
    end
  end

  describe '.latest_for_section' do
    before do
      # Create multiple revisions for the same section
      CodeRevision.create!(
        section_id: exercise.id,
        section_type: 'LmsProgrammingExercise',
        code: 'First revision',
        user: user,
        created_at: 2.hours.ago
      )
      
      CodeRevision.create!(
        section_id: exercise.id,
        section_type: 'LmsProgrammingExercise',
        code: 'Second revision',
        user: user,
        created_at: 1.hour.ago
      )
    end

    it 'returns the latest revision for section and user' do
      latest = CodeRevision.latest_for_section(exercise.id, 'LmsProgrammingExercise', user)
      expect(latest.code).to eq('Second revision')
    end

    it 'returns nil when no revisions exist' do
      other_user = create(:user)
      latest = CodeRevision.latest_for_section(exercise.id, 'LmsProgrammingExercise', other_user)
      expect(latest).to be_nil
    end
  end

  describe 'scopes' do
    let(:other_user) { create(:user) }
    let(:other_exercise) { create(:lms_programming_exercise) }

    before do
      create(:code_revision, user: user, section_id: exercise.id, created_at: 3.hours.ago)
      create(:code_revision, user: user, section_id: exercise.id, created_at: 1.hour.ago)
      create(:code_revision, user: other_user, section_id: exercise.id, created_at: 2.hours.ago)
      create(:code_revision, user: user, section_id: other_exercise.id, created_at: 30.minutes.ago)
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        revisions = CodeRevision.recent
        expect(revisions.first.created_at).to be >= revisions.last.created_at
      end
    end

    describe '.by_user' do
      it 'returns revisions for specific user' do
        revisions = CodeRevision.by_user(user)
        expect(revisions.count).to eq(3)
        expect(revisions.pluck(:user_id)).to all(eq(user.id))
      end
    end

    describe '.by_section' do
      it 'returns revisions for specific section' do
        mock_section = double('Section', id: exercise.id, class: double(name: 'LmsProgrammingExercise'))
        revisions = CodeRevision.by_section(mock_section)
        expect(revisions.count).to eq(3)
        expect(revisions.pluck(:section_id)).to all(eq(exercise.id.to_s))
      end
    end
  end

  describe 'code versioning workflow' do
    it 'supports typical auto-save workflow' do
      # Initial save
      revision1 = CodeRevision.autosave_for_section(
        exercise.id,
        'LmsProgrammingExercise',
        'def initial(): pass',
        user
      )

      # User makes changes, auto-save again
      revision2 = CodeRevision.autosave_for_section(
        exercise.id,
        'LmsProgrammingExercise',
        'def improved(): return "better"',
        user
      )

      # Verify both revisions exist
      expect(CodeRevision.count).to eq(2)
      
      # Latest should return the most recent
      latest = CodeRevision.latest_for_section(exercise.id, 'LmsProgrammingExercise', user)
      expect(latest.id).to eq(revision2.id)
      expect(latest.code).to eq('def improved(): return "better"')

      # History should show both
      history = CodeRevision.where(
        section_id: exercise.id,
        section_type: 'LmsProgrammingExercise',
        user: user
      ).order(created_at: :desc)
      
      expect(history.count).to eq(2)
      expect(history.first.code).to eq('def improved(): return "better"')
      expect(history.last.code).to eq('def initial(): pass')
    end
  end

  describe 'metadata and notes' do
    it 'supports additional metadata' do
      revision = create(:code_revision,
                       code: 'print("test")',
                       notes: 'Fixed the bug',
                       metadata: { language: 'python', line_count: 1 })
      
      expect(revision.notes).to eq('Fixed the bug')
      expect(revision.metadata['language']).to eq('python')
      expect(revision.metadata['line_count']).to eq(1)
    end
  end
end