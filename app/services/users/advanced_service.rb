module Users
  class AdvancedService
    def self.get_roles
      roles = Role.active.order(:name)

      roles.map do |role|
        {
          name: role.name,
          role_name: role.role_name,
          description: role.description,
          status: role.status
        }
      end
    end

    def self.add_evaluator(user_email, evaluator_role = "Batch Evaluator")
      user = User.find_by(email: user_email)
      return { success: false, error: "User not found" } unless user

      # Check if user already has this role
      if HasRole.user_has_role?(user, evaluator_role)
        return { success: false, error: "User already has #{evaluator_role} role" }
      end

      # Assign the role
      HasRole.assign_role_to_user(user, evaluator_role)

      { success: true, message: "#{evaluator_role} role assigned to #{user_email}" }
    rescue => e
      { success: false, error: "Failed to add evaluator role: #{e.message}" }
    end

    def self.delete_evaluator(user_email, evaluator_role = "Batch Evaluator")
      user = User.find_by(email: user_email)
      return { success: false, error: "User not found" } unless user

      # Check if user has this role
      unless HasRole.user_has_role?(user, evaluator_role)
        return { success: false, error: "User does not have #{evaluator_role} role" }
      end

      # Remove the role
      HasRole.remove_role_from_user(user, evaluator_role)

      { success: true, message: "#{evaluator_role} role removed from #{user_email}" }
    rescue => e
      { success: false, error: "Failed to remove evaluator role: #{e.message}" }
    end

    def self.save_role(user_email, role_name)
      user = User.find_by(email: user_email)
      return { success: false, error: "User not found" } unless user

      # Validate role exists
      role = Role.find_by(role_name: role_name)
      return { success: false, error: "Invalid role: #{role_name}" } unless role

      # Remove existing roles and assign new one
      HasRole.where(user: user).destroy_all
      HasRole.assign_role_to_user(user, role_name)

      { success: true, message: "Role #{role_name} assigned to #{user_email}" }
    rescue => e
      { success: false, error: "Failed to save role: #{e.message}" }
    end

    def self.assign_badge(user_email, badge_name)
      user = User.find_by(email: user_email)
      return { success: false, error: "User not found" } unless user

      badge = LmsBadge.find_by(name: badge_name)
      return { success: false, error: "Badge not found" } unless badge

      # Check if user already has this badge
      existing_assignment = LmsBadgeAssignment.find_by(badge: badge, member: user)
      if existing_assignment
        return { success: false, error: "User already has this badge" }
      end

      # Check badge eligibility
      unless badge.is_eligible_for_user?(user)
        return { success: false, error: "User is not eligible for this badge" }
      end

      # Check issuance limit
      if badge.issuance_limit && badge.issuance_limit > 0 && badge.get_award_count(user) >= badge.issuance_limit
        return { success: false, error: "Badge issuance limit reached for this user" }
      end

      # Create badge assignment
      assignment = LmsBadgeAssignment.create!(
        badge: badge,
        member: user,
        issued_on: Time.current,
        status: "Active",
        expires_on: badge.expires_after_days ? badge.expires_after_days.days.from_now : nil
      )

      # Create badge award record
      LmsBadgeAward.create!(
        badge: badge,
        user: user,
        awarded_at: Time.current,
        awarded_by: Current.user, # Assuming current user context
        context: "manual_assignment",
        metadata: { assigned_by: "system", reason: "manual_assignment" }
      )

      # Update badge statistics
      badge.update_award_count

      { success: true, message: "Badge #{badge_name} assigned to #{user_email}", assignment_id: assignment.id }
    rescue => e
      { success: false, error: "Failed to assign badge: #{e.message}" }
    end

    def self.get_meta_info(user_email)
      user = User.find_by(email: user_email)
      return { success: false, error: "User not found" } unless user

      {
        success: true,
        meta_info: {
          user_id: user.id,
          email: user.email,
          full_name: user.full_name,
          roles: user.roles,
          badges: user.badges || [],
          profile_completion: calculate_profile_completion(user),
          last_login: user.last_sign_in_at&.strftime("%Y-%m-%d %H:%M:%S"),
          created_at: user.created_at.strftime("%Y-%m-%d %H:%M:%S")
        }
      }
    rescue => e
      { success: false, error: "Failed to get meta info: #{e.message}" }
    end

    def self.update_meta_info(user_email, meta_data)
      user = User.find_by(email: user_email)
      return { success: false, error: "User not found" } unless user

      # Update allowed meta fields
      allowed_fields = [ :bio, :headline, :company, :location, :website, :linkedin, :github, :phone ]
      update_data = {}

      meta_data.each do |key, value|
        if allowed_fields.include?(key.to_sym)
          update_data[key] = value
        end
      end

      if update_data.any?
        user.update!(update_data)
        { success: true, message: "Meta info updated successfully" }
      else
        { success: false, error: "No valid fields to update" }
      end
    rescue => e
      { success: false, error: "Failed to update meta info: #{e.message}" }
    end

    private

    def self.calculate_profile_completion(user)
      fields = [ :first_name, :last_name, :bio, :headline, :company, :location, :user_image ]
      completed_fields = fields.count { |field| user.send(field).present? }
      ((completed_fields.to_f / fields.size) * 100).round
    end
  end
end
