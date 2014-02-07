module Account
  class LoginController < ::Account::ApplicationController
    helper Shared::Helper::Errors

    def new
      login!(current_user) and return if current_user
      @user = Account::User.new
    end

    def create
      @user = User.find_by_email(account_params[:email])
      try_again and return unless @user
      try_again and return unless @user.authenticate(account_params[:password])
      login!(@user)
    end

    def destroy
      logout!
    end

    protected

    def try_again
      @user = Account::User.new(account_params)
      @user.errors.add(:base, "Account not found.")
      render :new
    end

    def account_params
      params.require(:user).permit(:email, :password)
    end
  end
end
