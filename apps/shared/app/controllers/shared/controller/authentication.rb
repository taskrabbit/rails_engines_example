module Shared
  module Controller
    module Authentication
      extend ::ActiveSupport::Concern

      included do
        helper_method :logged_in?
        helper_method :current_user
      end


      def logged_in?
        !!current_user
      end

      def current_user
        return @current_user if defined?(@current_user)
        @current_user = nil
        return nil unless session[:current_user_id]

        namespace = self.class.name.split('::').first
        klass     = "#{namespace}::User".constantize rescue nil
        klass   ||= Shared::User::Stub

        @current_user = klass.find_by_id(session[:current_user_id])
      end

      protected

      def require_user
        redirect_to "/" unless current_user
      end
    end
  end
end