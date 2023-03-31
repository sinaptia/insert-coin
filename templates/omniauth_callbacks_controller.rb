class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  private

  def omniauth_authentication
    auth = request.env["omniauth.auth"]

    @identity = Identity.find_or_create_by uid: auth["uid"], provider: auth["provider"]
    @identity.update auth_data: auth.as_json

    if signed_in?
      if @identity.user == current_user
        redirect_to root_path, notice: t(".already_linked")
      else
        @identity.update user: current_user

        redirect_to root_path, notice: t(".successfully_linked")
      end
    elsif @identity.user.blank?
      @user = User.find_or_initialize_by email: auth.dig("info", "email")
      @user.update(password: Devise.friendly_token[0, 20]) if @user.new_record?

      @identity.update user: @user

      sign_in @identity.user
      redirect_to root_path
    else
      sign_in_and_redirect @identity.user
    end
  end
end
