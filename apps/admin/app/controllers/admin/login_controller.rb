module Admin
  class LoginController < ::Admin::ApplicationController
    helper Shared::Helper::Errors

    skip_before_filter :require_admin_user

    def new
      login!(current_user) and return if current_user
      @user = Admin::User.new
    end

    def create
      @user = Admin::User.find_by_email(account_params[:email])
      try_again and return unless @user
      try_again and return unless @user.authenticate(account_params[:password]) 
      try_again and return unless @user.admin?
      login!(@user)
    end

    def destroy
      logout!
    end

    protected

    def try_again
      @user = Admin::User.new(account_params)
      @user.errors.add(:base, "Account not found.")
      render :new
    end

    def account_params
      params.require(:user).permit(:email, :password)
    end
  end
end
