class BlogsController < ApplicationController
  before_action :set_blog, only: [:show]
  
  def index
    @q = Blog.approved.ransack(params[:q])
    @blogs = @q.result.includes(:posts).page(params[:page]).per(20)
    
    respond_to do |format|
      format.html
      format.json { render json: @blogs.as_json(include: :posts) }
    end
  end
  
  def show
    @posts = @blog.posts.recent.page(params[:page]).per(10)
    
    respond_to do |format|
      format.html
      format.json { render json: @blog.as_json(include: :posts) }
    end
  end
  
  def create
    @blog = Blog.new(blog_params)
    @blog.is_approved = false # Require manual approval
    
    if @blog.save
      render json: { status: 'success', message: 'Blog submitted for review', blog: @blog }, status: :created
    else
      render json: { status: 'error', errors: @blog.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_blog
    @blog = Blog.approved.find(params[:id])
  end
  
  def blog_params
    params.require(:blog).permit(:username, :description, :hyperlink, :rss)
  end
end
