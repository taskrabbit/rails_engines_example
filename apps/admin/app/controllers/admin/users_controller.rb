module Admin
  class UsersController < ::Admin::PanelController
    prepend_before_filter :fetch_object

    def show

    end

    def posts
      @posts = Admin::Post.where(user_id: @user.id).page(params[:page])
    end

    def edit

    end

    def update
      if @user.update_attributes(object_params)
        redirect_to @user
      else
        flash[:alert] = @user.errors.full_messages.join(',')
        render :edit
      end
    end

    protected

    def fetch_object
      @user ||= Admin::User.find(params[:id])
    end

    def object_params
      params.require(:user).permit!
    end
  end
end
