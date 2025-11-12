module Users
  class UsersService
    def self.call
      new.call
    end

    def call
      users = User.where(status: "Active")
                  .select(:id, :full_name, :profile_image)

      # Return hash format matching Frappe: {user_id: {name, full_name, user_image}}
      users_hash = {}
      users.each do |user|
        users_hash[user.id] = {
          name: user.id,
          full_name: user.full_name,
          user_image: user.profile_image
        }
      end

      users_hash
    end
  end
end
