class Admin::BlogsController < ApplicationController
  before_action :set_blog, only: [:show, :edit, :update, :approve, :reject, :refresh_posts, :check_status, :update_karma]
  
  def index
    @q = Blog.ransack(params[:q])
    @blogs = @q.result.includes(:posts).page(params[:page]).per(20)
    
    @pending_count = Blog.where(is_approved: false).count
    @total_count = Blog.count
    @online_count = Blog.where(is_online: true).count
  end
  
  def show
    @posts = @blog.posts.recent.page(params[:page]).per(10)
  end
  
  def edit
  end
  
  def update
    if @blog.update(blog_params)
      redirect_to admin_blog_path(@blog), notice: 'Blog updated successfully'
    else
      render :edit
    end
  end
  
  def approve
    @blog.update!(is_approved: true)
    redirect_to admin_blogs_path, notice: "#{@blog.username} approved"
  end
  
  def reject
    @blog.update!(is_approved: false)
    redirect_to admin_blogs_path, notice: "#{@blog.username} rejected"
  end
  
  def refresh_posts
    UpdateBlogPostsJob.perform_async(@blog.id)
    redirect_to admin_blog_path(@blog), notice: 'Post refresh job queued'
  end
  
  def check_status
    CheckBlogStatusJob.perform_async(@blog.id)
    redirect_to admin_blog_path(@blog), notice: 'Status check job queued'
  end
  
  def update_karma
    UpdateKarmaJob.perform_async(@blog.id)
    redirect_to admin_blog_path(@blog), notice: 'Karma update job queued'
  end
  
  private
  
  def set_blog
    @blog = Blog.find(params[:id])
  end
  
  def blog_params
    params.require(:blog).permit(:username, :description, :hyperlink, :rss, :is_approved, :is_online)
  end
end