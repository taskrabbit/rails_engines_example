module Admin
  class ApplicationController < ActionController::Base
    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    protect_from_forgery with: :exception

    layout 'admin/layouts/admin'
    include Shared::Controller::Manifests
    
    helper_method :current_user

    before_filter :require_admin_user

    def login!(user)
      session[:admin_user_id] = user.id
      redirect_to '/admin'
    end

    def logout!
      session.delete(:admin_user_id)
      redirect_to '/admin/login'
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = nil
      return nil unless session[:admin_user_id]
      @current_user = Admin::User.find_by_id(session[:admin_user_id])
    end

    # for layout
    helper_method :skip_sidebar
    def skip_sidebar
      @skip_sidebar = true
    end


    protected

    def require_admin_user
      redirect_to "/admin/login" and return unless current_user
      logout! unless current_user.admin?
    end

  end
end
