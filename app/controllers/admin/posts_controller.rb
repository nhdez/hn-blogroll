class Admin::PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_post, only: [:show, :destroy]
  
  def index
    @q = Post.joins(:blog).ransack(params[:q])
    @posts = @q.result(distinct: true).includes(:blog).recent.page(params[:page]).per(20)
    
    @total_count = Post.count
    @recent_count = Post.where('created_at > ?', 1.week.ago).count
  end
  
  def show
  end
  
  def destroy
    @post.destroy
    redirect_to admin_posts_path, notice: 'Post deleted successfully'
  end
  
  private
  
  def set_post
    @post = Post.find(params[:id])
  end
end