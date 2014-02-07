module Account
  class ApplicationController < ActionController::Base
    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    protect_from_forgery with: :exception
    
    include Shared::Controller::Layout

    def login!(user)
      session[:current_user_id] = user.id
      redirect_to '/posts'
    end

    def logout!
      session.delete(:current_user_id)
      redirect_to '/'
    end
  end
  
end



