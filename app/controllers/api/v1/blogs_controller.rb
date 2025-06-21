class Api::V1::BlogsController < ApplicationController
  before_action :set_blog, only: [:show]
  
  def index
    @q = Blog.approved.ransack(params[:q])
    @blogs = @q.result.includes(:posts).page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      blogs: @blogs.as_json(include: { posts: { only: [:id, :title, :url, :published_at, :summary] } }),
      meta: {
        current_page: @blogs.current_page,
        total_pages: @blogs.total_pages,
        total_count: @blogs.total_count
      }
    }
  end
  
  def show
    render json: @blog.as_json(include: { posts: { only: [:id, :title, :url, :published_at, :summary, :content] } })
  end
  
  private
  
  def set_blog
    @blog = Blog.approved.find(params[:id])
  end
end