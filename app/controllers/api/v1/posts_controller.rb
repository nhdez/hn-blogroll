class Api::V1::PostsController < ApplicationController
  before_action :set_post, only: [:show]
  
  def index
    @q = Post.joins(:blog).where(blogs: { is_approved: true }).ransack(params[:q])
    @posts = @q.result(distinct: true).includes(:blog).recent.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      posts: @posts.as_json(include: { blog: { only: [:id, :username, :hyperlink, :domain] } }),
      meta: {
        current_page: @posts.current_page,
        total_pages: @posts.total_pages,
        total_count: @posts.total_count
      }
    }
  end
  
  def show
    render json: @post.as_json(include: { blog: { only: [:id, :username, :hyperlink, :domain] } })
  end
  
  private
  
  def set_post
    @post = Post.joins(:blog).where(blogs: { is_approved: true }).find(params[:id])
  end
end