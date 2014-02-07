module Account
  class UsersController < ::Account::ApplicationController
    helper Shared::Helper::Errors

    def new
      login!(current_user) and return if current_user
      @user = Account::User.new
    end

    def create
      @user = User.new(account_params)
      if @user.save
        login!(@user)
      else
        render :new
      end
    end

    protected

    def account_params
      params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
    end
  end
end
