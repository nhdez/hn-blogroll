class PostsController < ApplicationController
  before_action :set_post, only: [:show]
  
  def index
    @q = Post.joins(:blog).where(blogs: { is_approved: true }).ransack(params[:q])
    @posts = @q.result(distinct: true).includes(:blog).recent.page(params[:page]).per(20)
    
    respond_to do |format|
      format.html
      format.json { render json: @posts.as_json(include: :blog) }
    end
  end
  
  def show
    respond_to do |format|
      format.html
      format.json { render json: @post.as_json(include: :blog) }
    end
  end
  
  private
  
  def set_post
    @post = Post.joins(:blog).where(blogs: { is_approved: true }).find(params[:id])
  end
end