module Users
  class UsersService
    def self.call
      new.call
    end

    def call
      users = User.where(status: "Active")
                  .select(:id, :email, :username, :first_name, :last_name, :full_name, :profile_image)

      # Return array format matching Frappe test expectations
      users_array = users.map do |user|
        {
          name: user.id,
          email: user.email,
          username: user.username,
          first_name: user.first_name,
          last_name: user.last_name,
          full_name: user.full_name,
          user_image: user.profile_image
        }
      end

      { data: users_array }
    end
  end
end
