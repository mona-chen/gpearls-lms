# frozen_string_literal: true

class Role < ApplicationRecord
  # Associations
  has_many :has_roles, dependent: :destroy, class_name: "HasRole"
  has_many :users, through: :has_roles

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :role_name, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[Active Inactive] }

  # Scopes
  scope :active, -> { where(status: "Active") }
  scope :inactive, -> { where(status: "Inactive") }

  # Callbacks
  before_validation :set_default_values

  # Instance Methods
  def active?
    status == "Active"
  end

  def to_frappe_format
    {
      id: id,
      name: name,
      role_name: role_name,
      description: description,
      status: status
    }
  end

  # Class Methods
  def self.create_lms_roles
    create_role(name: "Course Creator", role_name: "Course Creator", description: "User who can create and manage courses", status: "Active")
    create_role(name: "Moderator", role_name: "Moderator", description: "User who can moderate course content", status: "Active")
    create_role(name: "Evaluator", role_name: "Evaluator", description: "User who can evaluate and grade assessments", status: "Active")
    create_role(name: "Student", role_name: "Student", description: "User who can participate in courses", status: "Active")
  end

  private

  def set_default_values
    self.status ||= "Active"
  end

  def build_role_with_defaults(params)
    Role.new(
      name: params[:name],
      role_name: params[:role_name],
      description: params[:description],
      status: params[:status] || "Active"
    )
  end
end
