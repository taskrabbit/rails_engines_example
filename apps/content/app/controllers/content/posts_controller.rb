module Content
  class PostsController < ::Content::ApplicationController
    helper Shared::Helper::Errors

    manifest :posts

    before_action :require_user
    before_action :load_post, only: [:show, :edit, :update, :destroy]

    def index
      @post = Content::Post.new
      show_index
    end

    def create
      @post = Post.new(post_params)
      @post.user = current_user

      if @post.save
        flash[:notice] = "Post saved"
        @post = Post.new
      end
      show_index
    end

    protected

    def show_index
      @posts = current_user.posts.page(params[:page]).per(20)
      render :index
    end

    def load_post
      @post = Content::Post.find(params[:id])
      # say not found if not mine
      raise ActiveRecord::RecordNotFound unless @post.user_id == current_user.id
    end

    def post_params
      params.require(:post).permit(:content)
    end
  end
end
