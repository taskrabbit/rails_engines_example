module Admin
  class HomeController < ::Admin::ApplicationController

    before_action :skip_sidebar
    
    def index
      @post_search = Admin::PostSearch.new
      @user_search = Admin::UserSearch.new
    end

    def post_search
      op = Admin::PostSearch.new(current_user)
      if op.submit(params)
        @results = op.results
        if @results.size == 1
           redirect_to @results.first
        end
      else
        redirect_to root_path, alert: 'No results found'
      end
    end

    def user_search
      op = Admin::UserSearch.new(current_user)
      if op.submit(params)
        @results = op.results
        if @results.size == 1
           redirect_to @results.first
        end
      else
        redirect_to root_path, alert: 'No results found'
      end
    end
  end
end
