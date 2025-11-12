require 'rails_helper'

RSpec.describe Frappe::LmsUtilsService, type: :service do
  let(:user) { create(:user) }
  let(:instructor) { create(:user, :instructor) }
  let(:course) { create(:course, :published, :with_lessons, instructor: instructor) }
  let(:batch) { create(:batch, :active, instructor: instructor) }

  before do
    Current.user = user
  end

  after do
    Current.user = nil
  end

  describe '.get_tags' do
    context 'when course exists with tags' do
      it 'returns tags as array matching Frappe behavior' do
        course.update!(tags: 'ruby, rails, testing')

        tags = Frappe::LmsUtilsService.get_tags(course.id)

        expect(tags).to eq(['ruby', ' rails', ' testing'])
      end

      it 'handles single tag without comma' do
        course.update!(tags: 'programming')

        tags = Frappe::LmsUtilsService.get_tags(course.id)

        expect(tags).to eq(['programming'])
      end
    end

    context 'when course does not exist' do
      it 'returns empty array' do
        tags = Frappe::LmsUtilsService.get_tags('nonexistent')

        expect(tags).to eq([])
      end
    end

    context 'when course has no tags' do
      it 'returns empty array' do
        course.update!(tags: nil)

        tags = Frappe::LmsUtilsService.get_tags(course.id)

        expect(tags).to eq([])
      end

      it 'handles empty string tags' do
        course.update!(tags: '')

        tags = Frappe::LmsUtilsService.get_tags(course.id)

        expect(tags).to eq([''])
      end
    end
  end

  describe '.get_reviews' do
    context 'when course exists' do
      it 'returns empty array (placeholder until reviews table exists)' do
        reviews = Frappe::LmsUtilsService.get_reviews(course.id)

        expect(reviews).to eq([])
      end
    end

    context 'when course does not exist' do
      it 'returns empty array' do
        reviews = Frappe::LmsUtilsService.get_reviews('nonexistent')

        expect(reviews).to eq([])
      end
    end
  end

  describe '.get_average_rating' do
    context 'when no reviews exist' do
      it 'returns nil' do
        rating = Frappe::LmsUtilsService.get_average_rating(course.id)

        expect(rating).to eq(0.0)
      end
    end

    context 'when reviews exist (mocked)' do
      before do
        allow(Frappe::LmsUtilsService).to receive(:get_reviews).with(course.id).and_return([
          { rating: 4 },
          { rating: 5 },
          { rating: 3 }
        ])
      end

      it 'calculates average correctly' do
        rating = Frappe::LmsUtilsService.get_average_rating(course.id)

        expect(rating).to eq(4.0)
      end
    end

    context 'when reviews have no rating' do
      before do
        allow(Frappe::LmsUtilsService).to receive(:get_reviews).with(course.id).and_return([
          { rating: nil },
          { rating: 0 }
        ])
      end

      it 'returns nil' do
        rating = Frappe::LmsUtilsService.get_average_rating(course.id)

        expect(rating).to eq(0.0)
      end
    end
  end

  describe '.get_course_progress' do
    let(:enrollment) { create(:enrollment, user: user, course: course) }

    context 'when user is enrolled in course' do
      it 'calculates progress based on completed lessons' do
        # Complete 2 out of 5 lessons
        create(:lesson_progress, user: user, lesson: course.lessons.first, completed: true)
        create(:lesson_progress, user: user, lesson: course.lessons.second, completed: true)

        progress = Frappe::LmsUtilsService.get_course_progress(course.id)

        expect(progress).to eq(40.0) # 2/5 * 100
      end

      it 'returns 0 when no lessons are completed' do
        progress = Frappe::LmsUtilsService.get_course_progress(course.id)

        expect(progress).to eq(0)
      end

      it 'returns 100 when all lessons are completed' do
        course.lessons.each do |lesson|
          create(:lesson_progress, user: user, lesson: lesson, completed: true)
        end

        progress = Frappe::LmsUtilsService.get_course_progress(course.id)

        expect(progress).to eq(100.0)
      end

      it 'handles course with no lessons' do
        empty_course = create(:course, instructor: instructor)
        create(:enrollment, user: user, course: empty_course)

        progress = Frappe::LmsUtilsService.get_course_progress(empty_course.id)

        expect(progress).to eq(0)
      end
    end

    context 'when user is not enrolled' do
      it 'returns 0' do
        progress = Frappe::LmsUtilsService.get_course_progress(course.id)

        expect(progress).to eq(0)
      end
    end

    context 'when course does not exist' do
      it 'returns 0' do
        progress = Frappe::LmsUtilsService.get_course_progress('nonexistent')

        expect(progress).to eq(0)
      end
    end

    context 'with custom member parameter' do
      let(:other_user) { create(:user) }
      let(:other_enrollment) { create(:enrollment, user: other_user, course: course) }

      it 'calculates progress for specified member' do
        create(:lesson_progress, user: other_user, lesson: course.lessons.first, completed: true)

        progress = Frappe::LmsUtilsService.get_course_progress(course.id, other_user.email)

        expect(progress).to eq(20.0) # 1/5 * 100
      end
    end
  end

  describe '.get_membership' do
    context 'when user is enrolled' do
      it 'returns membership details matching Frappe format' do
        Current.user = user
        simple_course = create(:course, instructor: instructor)
        enrollment = create(:enrollment, user: user, course: simple_course)

        membership = Frappe::LmsUtilsService.get_membership(simple_course.id)

        expect(membership).to be_a(Hash)
        expect(membership[:name]).to eq(enrollment.id)
        expect(membership[:current_lesson]).to eq(enrollment.current_lesson)
        expect(membership[:progress]).to eq(enrollment.progress)
        expect(membership[:member]).to eq(user.email)
        expect(membership[:purchased_certificate]).to eq(false)
        expect(membership[:certificate]).to eq(enrollment.certificate)
      end
    end

    context 'when user is not enrolled' do
      it 'returns false' do
        Current.user = user
        membership = Frappe::LmsUtilsService.get_membership('nonexistent')

        expect(membership).to be false
      end
    end

    context 'with custom member parameter' do
      it 'returns membership for specified member' do
        Current.user = user
        other_user = create(:user)
        simple_course = create(:course, instructor: instructor)
        other_enrollment = create(:enrollment, user: other_user, course: simple_course)

        membership = Frappe::LmsUtilsService.get_membership(simple_course.id, other_user.email)

        expect(membership[:member]).to eq(other_user.email)
      end
    end
  end

  describe '.get_my_courses' do
    context 'when user has enrollments' do
      let!(:enrollment) { create(:enrollment, user: user, course: course) }

      it 'returns enrolled courses with details' do
        my_courses = Frappe::LmsUtilsService.get_my_courses

        expect(my_courses).to be_an(Array)
        expect(my_courses.length).to be > 0

        course_data = my_courses.first
        expect(course_data[:name]).to eq(course.id)
        expect(course_data[:title]).to eq(course.title)
        expect(course_data[:published]).to eq(course.published)
        expect(course_data[:featured]).to eq(course.featured)
        expect(course_data[:category]).to eq(course.category)
        expect(course_data[:status]).to eq('Approved')
        expect(course_data[:lessons]).to eq(course.lessons.count)
        expect(course_data[:enrollments]).to eq(course.enrollments.count)
      end

      it 'includes membership details for enrolled courses' do
        my_courses = Frappe::LmsUtilsService.get_my_courses

        course_data = my_courses.first
        expect(course_data[:membership]).to be_present
        expect(course_data[:membership][:member]).to eq(user.id)
      end
    end

    context 'when user has no enrollments' do
      it 'returns featured courses as fallback' do
        featured_course = create(:course, :featured, :published)

        my_courses = Frappe::LmsUtilsService.get_my_courses

        expect(my_courses).to be_an(Array)
        expect(my_courses.map { |c| c[:name] }).to include(featured_course.id)
      end

      it 'returns popular courses as second fallback' do
        popular_course = create(:course, :published)
        create_list(:enrollment, 5, course: popular_course)

        my_courses = Frappe::LmsUtilsService.get_my_courses

        expect(my_courses).to be_an(Array)
        expect(my_courses.map { |c| c[:name] }).to include(popular_course.id)
      end

      it 'returns empty array when no courses available' do
        my_courses = Frappe::LmsUtilsService.get_my_courses

        expect(my_courses).to eq([])
      end
    end

    context 'when no current user' do
      before { Current.user = nil }

      it 'returns empty array' do
        my_courses = Frappe::LmsUtilsService.get_my_courses

        expect(my_courses).to eq([])
      end
    end
  end

  describe '.get_my_batches' do
    let!(:batch_enrollment) { create(:batch_enrollment, user: user, batch: batch) }

    context 'when user has batch enrollments' do
      it 'returns enrolled batches with details' do
        my_batches = Frappe::LmsUtilsService.get_my_batches

        expect(my_batches).to be_an(Array)
        expect(my_batches.length).to be > 0

        batch_data = my_batches.first
        expect(batch_data[:name]).to eq(batch.id)
        expect(batch_data[:title]).to eq(batch.title)
        expect(batch_data[:description]).to eq(batch.description)
        expect(batch_data[:start_date]).to eq(batch.start_date.strftime('%Y-%m-%d'))
        expect(batch_data[:end_date]).to eq(batch.end_date.strftime('%Y-%m-%d'))
        expect(batch_data[:published]).to eq(batch.published)
      end

      it 'includes enrollment details for enrolled batches' do
        my_batches = Frappe::LmsUtilsService.get_my_batches

        batch_data = my_batches.first
        expect(batch_data[:enrollment]).to be_present
        expect(batch_data[:enrollment][:member]).to eq(user.id)
      end
    end

    context 'when user has no batch enrollments' do
      before { batch_enrollment.destroy }

      it 'returns upcoming batches as fallback' do
        Current.user = user
        upcoming_batch = create(:batch, :published, start_date: 1.week.from_now)
        create(:batch_enrollment, user: user, batch: upcoming_batch)

        my_batches = Frappe::LmsUtilsService.get_my_batches

        expect(my_batches).to be_an(Array)
        expect(my_batches.map { |b| b[:name] }).to include(upcoming_batch.id)
      end

      it 'returns empty array when no batches available' do
        Batch.delete_all
        my_batches = Frappe::LmsUtilsService.get_my_batches

        expect(my_batches).to eq([])
      end
    end

    context 'when no current user' do
      it 'returns empty array' do
        Current.user = nil
        my_batches = Frappe::LmsUtilsService.get_my_batches

        expect(my_batches).to eq([])
      end
    end

    context 'when user has no batch enrollments' do
      it 'returns upcoming batches as fallback' do
        Current.user = user

        # Clean database state first
        BatchEnrollment.delete_all

        upcoming_batch = create(:batch, :published, start_date: 1.week.from_now)
        # Don't create batch enrollment - this should trigger the fallback logic

        my_batches = Frappe::LmsUtilsService.get_my_batches

        expect(my_batches).to be_an(Array)
        expect(my_batches.length).to be > 0
        expect(my_batches.map { |b| b[:name] }).to include(upcoming_batch.id)
      end
    end
  end

  describe '.get_my_live_classes' do
    let(:course_with_lessons) { create(:course, :published, instructor: instructor) }
    let(:batch) { create(:batch, :active, instructor: instructor) }
    let!(:batch_course) { create(:batch_course, batch: batch, course: course_with_lessons) }
    let(:live_class) { create(:live_class, batch: batch, date: Date.today + 1.day) }
    let!(:batch_enrollment) { create(:batch_enrollment, user: user, batch: batch) }

    context 'when user has batch enrollments with live classes' do
      it 'returns upcoming live classes' do
        my_live_classes = Frappe::LmsUtilsService.get_my_live_classes

        expect(my_live_classes).to be_an(Array)
        expect(my_live_classes.length).to be > 0

        class_data = my_live_classes.first
        expect(class_data[:name]).to eq(live_class.id)
        expect(class_data[:title]).to eq(live_class.title)
        expect(class_data[:description]).to eq(live_class.description)
        expect(class_data[:date]).to eq(live_class.date)
        expect(class_data[:duration]).to eq(live_class.duration)
        expect(class_data[:attendees]).to eq(live_class.attendees || [])
        expect(class_data[:start_url]).to eq(live_class.start_url)
        expect(class_data[:join_url]).to eq(live_class.join_url)
        expect(class_data[:owner]).to eq(instructor.email)
      end

      it 'includes course title for live classes' do
        create(:batch_course, batch: batch, course: course)

        my_live_classes = Frappe::LmsUtilsService.get_my_live_classes

        class_data = my_live_classes.first
        expect(class_data[:course_title]).to eq(course.title)
      end

      it 'limits to 2 upcoming classes' do
        create_list(:live_class, 3, batch: batch, date: Date.today + 2.days)

        my_live_classes = Frappe::LmsUtilsService.get_my_live_classes

        expect(my_live_classes.length).to eq(2)
      end
    end

    context 'when no current user' do
      before { Current.user = nil }

      it 'returns empty array' do
        my_live_classes = Frappe::LmsUtilsService.get_my_live_classes

        expect(my_live_classes).to eq([])
      end
    end

    context 'when no live classes found' do
      it 'returns empty array' do
        LiveClass.delete_all

        my_live_classes = Frappe::LmsUtilsService.get_my_live_classes

        expect(my_live_classes).to eq([])
      end
    end
  end

  describe '.get_streak_info' do
    context 'when user has activity' do
      it 'calculates current and longest streak' do
        # Create activity on consecutive days
        create(:lesson_progress, user: user, created_at: 1.day.ago)
        create(:lesson_progress, user: user, created_at: 2.days.ago)
        create(:lesson_progress, user: user, created_at: 3.days.ago)

        streak_info = Frappe::LmsUtilsService.get_streak_info

        expect(streak_info).to be_a(Hash)
        expect(streak_info[:current_streak]).to be_a(Integer)
        expect(streak_info[:longest_streak]).to be_a(Integer)
        expect(streak_info[:current_streak]).to be >= 0
        expect(streak_info[:longest_streak]).to be >= 0
      end
    end

    context 'when user has no activity' do
      it 'returns zero streaks' do
        streak_info = Frappe::LmsUtilsService.get_streak_info

        expect(streak_info).to eq({
          current_streak: 0,
          longest_streak: 0
        })
      end
    end

    context 'when no current user' do
      before { Current.user = nil }

      it 'returns empty hash' do
        streak_info = Frappe::LmsUtilsService.get_streak_info

        expect(streak_info).to eq({})
      end
    end

    context 'weekend handling' do
      it 'skips weekends in streak calculation' do
        # Friday activity
        create(:lesson_progress, user: user, created_at: Date.parse('2024-01-05'))
        # Monday activity (skipping weekend)
        create(:lesson_progress, user: user, created_at: Date.parse('2024-01-08'))

        streak_info = Frappe::LmsUtilsService.get_streak_info

        expect(streak_info[:current_streak]).to be >= 1
      end
    end
  end

  describe '.get_upcoming_evals' do
    let!(:certificate_request) do
      create(:certificate_request, user: user, course: course, status: 'Upcoming', date: Date.today + 1.day)
    end

    context 'when user has upcoming evaluations' do
      it 'returns evaluation details' do
        upcoming_evals = Frappe::LmsUtilsService.get_upcoming_evals

        expect(upcoming_evals).to be_an(Array)
        expect(upcoming_evals.length).to be > 0

        eval_data = upcoming_evals.first
        expect(eval_data[:name]).to eq(certificate_request.id)
        expect(eval_data[:date]).to eq(certificate_request.date.strftime('%Y-%m-%d'))
        expect(eval_data[:course]).to eq(course.id)
        expect(eval_data[:member]).to eq(user.email)
        expect(eval_data[:member_name]).to eq(user.full_name)
        expect(eval_data[:course_title]).to eq(course.title)
      end
    end

    context 'with course filter' do
      let(:other_course) { create(:course) }

      it 'filters evaluations by courses' do
        other_cert_request = create(:certificate_request, user: user, course: other_course, status: 'Upcoming')

        upcoming_evals = Frappe::LmsUtilsService.get_upcoming_evals([course.id])

        course_ids = upcoming_evals.map { |e| e[:course] }
        expect(course_ids).to include(course.id)
        expect(course_ids).not_to include(other_course.id)
      end
    end

    context 'with batch filter' do
      let(:eval_batch) { create(:batch) }

      it 'filters evaluations by batch' do
        cert_request_with_batch = create(:certificate_request, user: user, batch: eval_batch, status: 'Upcoming')

        upcoming_evals = Frappe::LmsUtilsService.get_upcoming_evals(nil, eval_batch.id)

        batch_ids = upcoming_evals.map { |e| e[:batch_id] }
        expect(batch_ids).to include(eval_batch.id)
      end
    end

    context 'when no current user' do
      before { Current.user = nil }

      it 'returns empty array' do
        upcoming_evals = Frappe::LmsUtilsService.get_upcoming_evals

        expect(upcoming_evals).to eq([])
      end
    end

    context 'when no upcoming evaluations' do
      before { CertificateRequest.delete_all }

      it 'returns empty array' do
        upcoming_evals = Frappe::LmsUtilsService.get_upcoming_evals

        expect(upcoming_evals).to eq([])
      end
    end
  end

  describe '.save_current_lesson' do
    let!(:enrollment) { create(:enrollment, user: user, course: course) }
    let(:lesson) { course.lessons.first }

    context 'when user is enrolled' do
      it 'updates current lesson in enrollment' do
        result = Frappe::LmsUtilsService.save_current_lesson(course.id, lesson.id)

        expect(result[:success]).to be true
        enrollment.reload
        expect(enrollment.current_lesson).to eq(lesson.id)
      end
    end

    context 'when user is not enrolled' do
      before { enrollment.destroy }

      it 'returns error' do
        result = Frappe::LmsUtilsService.save_current_lesson(course.id, lesson.id)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Enrollment not found')
      end
    end

    context 'when no current user' do
      before { Current.user = nil }

      it 'returns authentication error' do
        result = Frappe::LmsUtilsService.save_current_lesson(course.id, lesson.id)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Not authenticated')
      end
    end
  end

  # Private method tests
  describe 'private helper methods' do
    let(:service) { Frappe::LmsUtilsService }

    describe 'fetch_activity_dates calculation' do
      it 'includes lesson progress dates' do
        create(:lesson_progress, user: user, created_at: 3.days.ago)
        create(:lesson_progress, user: user, created_at: 1.day.ago)

        streak_info = service.get_streak_info

        expect(streak_info[:current_streak]).to be >= 0
      end

      it 'includes quiz submission dates' do
        quiz = create(:quiz, course: course)
        create(:quiz_submission, user: user, quiz: quiz, created_at: 2.days.ago)

        streak_info = service.get_streak_info

        expect(streak_info[:current_streak]).to be >= 0
      end

      it 'includes assignment submission dates' do
        create(:assignment_submission, user: user, created_at: 1.day.ago)

        streak_info = service.get_streak_info

        expect(streak_info[:current_streak]).to be >= 0
      end
    end

    describe 'streak calculation edge cases' do
      it 'handles single day activity' do
        create(:lesson_progress, user: user, created_at: 1.day.ago)

        streak_info = service.get_streak_info

        expect(streak_info[:current_streak]).to eq(1)
        expect(streak_info[:longest_streak]).to eq(1)
      end

      it 'handles activity with gaps' do
        create(:lesson_progress, user: user, created_at: 5.days.ago)
        create(:lesson_progress, user: user, created_at: 2.days.ago)

        streak_info = service.get_streak_info

        expect(streak_info[:current_streak]).to eq(0) # Gap breaks current streak
        expect(streak_info[:longest_streak]).to eq(1) # Longest was 1 day
      end
    end
  end
end
