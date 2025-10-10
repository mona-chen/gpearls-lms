class Api::UsersController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:get_user_info]

  def get_user_info
    if current_user
      user = current_user.session_user
      user['is_fc_site'] = false
      user['is_system_manager'] = current_user.moderator?
      user['sitename'] = 'lms-api'
      user['developer_mode'] = Rails.env.development?
      user['site_info'] = {} if current_user.moderator?

      render json: user
    else
      render json: nil
    end
  end

  def get_all_users
    return render json: { error: 'Unauthorized' }, status: :forbidden unless current_user&.moderator?

    users = User.where(enabled: true).map do |user|
      {
        name: user.id,
        username: user.username,
        full_name: user.full_name,
        user_image: user.user_image
      }
    end

    render json: users
  end
  
  def get_members
    search = params[:search] || ''
    users = User.where(enabled: true)
                .where('full_name ILIKE ? OR username ILIKE ? OR email ILIKE ?', "%#{search}%", "%#{search}%", "%#{search}%")
                .limit(50)
                .map do |user|
                  {
                    name: user.id,
                    username: user.username,
                    full_name: user.full_name,
                    user_image: user.user_image
                  }
                end
    
    render json: users
  end
end