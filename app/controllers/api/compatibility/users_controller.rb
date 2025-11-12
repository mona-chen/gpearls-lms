module Api
  module Compatibility
    class UsersController < BaseController
      def get_user_info
        return render_unauthorized unless current_user

        user_info = Users::UserInfoService.call(current_user)
        render json: { message: user_info }
      end

      def get_all_users
        users = User.select(:id, :email, :first_name, :last_name, :user_image)
                   .limit(10)

        users_data = users.map do |user|
          {
            name: user.full_name,
            email: user.email,
            username: user.email.split('@').first,
            first_name: user.first_name,
            last_name: user.last_name,
            user_image: user.user_image
          }
        end

        render json: { data: users_data }
      end
    end
  end
end