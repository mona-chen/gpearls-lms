class JobReport < ApplicationRecord
  # Remove belongs_to for Frappe compatibility - use string identifiers
  # belongs_to :job_opportunity
  # belongs_to :reported_by, class_name: "User"

  validates :job_opportunity, presence: true
  validates :reported_by, presence: true
  validates :reason, presence: true
  validates :description, length: { maximum: 1000 }

  enum reason: {
    inappropriate_content: 0,
    spam: 1,
    offensive_language: 2,
    misleading_information: 3,
    copyright_violation: 4,
    other: 5
  }

  enum status: {
    pending: 0,
    reviewed: 1,
    resolved: 2,
    dismissed: 3
  }

  after_create :notify_admins

  private

  def notify_admins
    # Find all admin users and notify them
    admin_users = User.where("roles LIKE ?", "%System Manager%")

    admin_users.each do |admin|
      Notifications::NotificationService.send_notification(
        "JobReport",
        "document_created",
        self,
        [ admin ]
      )
    end
  end
end
