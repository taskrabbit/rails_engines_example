module Admin
  class PostsController < ::Admin::PanelController
    prepend_before_filter :fetch_object

    def show

    end

    def edit

    end

    def update
      if @post.update_attributes(object_params)
        redirect_to @post
      else
        flash[:alert] = @post.errors.full_messages.join(',')
        render :edit
      end
    end

    protected

    def fetch_object
      @post ||= Admin::Post.find(params[:id])
    end

    def object_params
      params.require(:post).permit!
    end
  end
end
