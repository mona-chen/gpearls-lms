class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :timeoutable
  devise :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # LMS associations
  has_many :enrollments, dependent: :destroy
  has_many :batch_enrollments, dependent: :destroy
  has_many :courses, through: :enrollments
  has_many :batches, through: :batch_enrollments
  has_many :lesson_progress, dependent: :destroy

  # LMS specific roles
  ROLES = %w[student instructor moderator evaluator]

  def instructor?
    is_instructor
  end

  def moderator?
    is_moderator
  end

  def evaluator?
    is_evaluator
  end

  def student?
    is_student
  end

  def roles
    roles = []
    roles << 'Course Creator' if instructor?
    roles << 'Moderator' if moderator?
    roles << 'Batch Evaluator' if evaluator?
    roles << 'LMS Student' if student?
    roles
  end
  
  def first_name
    full_name&.split&.first || 'User'
  end
  
  def last_name
    full_name&.split&.last || ''
  end
  
  def session_user
    {
      name: id,
      username: username,
      full_name: full_name,
      email: email,
      user_image: user_image,
      is_moderator: is_moderator,
      is_instructor: is_instructor,
      is_evaluator: is_evaluator,
      is_student: is_student,
      user_type: user_type,
      roles: roles
    }
  end
end