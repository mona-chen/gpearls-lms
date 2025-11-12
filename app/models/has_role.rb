# frozen_string_literal: true

class HasRole < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :parent, presence: true
  validates :parenttype, presence: true
  validates :role, presence: true
  validates :user, presence: true
  validates :parent, uniqueness: { scope: [ :role, :user ] }

  # Scopes
  scope :by_user, ->(user) { where(user: user) }
  scope :by_role, ->(role) { where(role: role) }
  scope :by_parent, ->(parent) { where(parent: parent) }

  # Callbacks
  before_validation :set_defaults

  # Class Methods
  def self.assign_role_to_user(user, role_name, parent: nil)
    parent ||= user.email

    find_or_create_by!(
      parent: parent,
      parenttype: "User",
      role: role_name,
      user: user
    )
  end

  def self.remove_role_from_user(user, role_name)
    where(user: user, role: role_name).destroy_all
  end

  def self.user_has_role?(user, role_name)
    exists?(user: user, role: role_name)
  end

  # Instance Methods
  def to_frappe_format
    {
      name: id,
      parent: parent,
      parenttype: parenttype,
      role: role,
      user: user&.email,
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  private

  def set_defaults
    self.parent ||= user&.email
    self.parenttype ||= "User"
  end
end
