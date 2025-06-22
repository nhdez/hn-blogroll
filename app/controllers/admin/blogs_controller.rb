class Admin::BlogsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_blog, only: [:show, :edit, :update, :approve, :reject, :refresh_posts, :check_status, :update_karma]
  
  def index
    @filter = params[:filter] || 'all'
    
    case @filter
    when 'pending'
      @q = Blog.pending.ransack(params[:q])
    when 'approved'
      @q = Blog.approved.ransack(params[:q])
    when 'rejected'
      @q = Blog.rejected.ransack(params[:q])
    else
      @q = Blog.ransack(params[:q])
    end
    
    @blogs = @q.result.includes(:posts).order(created_at: :desc).page(params[:page]).per(20)
    
    # Statistics
    @stats = {
      pending: Blog.pending.count,
      approved: Blog.approved.count,
      rejected: Blog.rejected.count,
      total: Blog.count,
      online: Blog.where(is_online: true).count,
      recent_submissions: Blog.where('submitted_at > ?', 1.week.ago).count
    }
  end
  
  def pending
    redirect_to admin_blogs_path(filter: 'pending')
  end
  
  def approved
    redirect_to admin_blogs_path(filter: 'approved')
  end
  
  def rejected
    redirect_to admin_blogs_path(filter: 'rejected')
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
    notes = params[:admin_notes]
    @blog.approve!('admin', notes)
    
    Rails.logger.info "Blog approved: #{@blog.username} (#{@blog.hyperlink}) by admin"
    
    # Start fetching posts if RSS is available
    if @blog.rss.present?
      UpdateBlogPostsJob.perform_async(@blog.id)
    end
    
    redirect_back(fallback_location: admin_blogs_path, notice: "✅ #{@blog.username || @blog.submitter_display_name} approved successfully")
  end
  
  def reject
    reason = params[:rejection_reason] || 'Blog does not meet our submission guidelines'
    notes = params[:admin_notes]
    
    @blog.reject!(reason, 'admin', notes)
    
    Rails.logger.info "Blog rejected: #{@blog.username} (#{@blog.hyperlink}) by admin - Reason: #{reason}"
    
    redirect_back(fallback_location: admin_blogs_path, notice: "❌ #{@blog.username || @blog.submitter_display_name} rejected")
  end
  
  def bulk_approve
    blog_ids = params[:blog_ids] || []
    count = 0
    
    blog_ids.each do |blog_id|
      blog = Blog.find(blog_id)
      if blog.pending?
        blog.approve!('admin', 'Bulk approval')
        UpdateBlogPostsJob.perform_async(blog.id) if blog.rss.present?
        count += 1
      end
    end
    
    redirect_to admin_blogs_path, notice: "✅ #{count} blogs approved successfully"
  end
  
  def bulk_reject
    blog_ids = params[:blog_ids] || []
    reason = params[:bulk_rejection_reason] || 'Does not meet submission guidelines'
    count = 0
    
    blog_ids.each do |blog_id|
      blog = Blog.find(blog_id)
      if blog.pending?
        blog.reject!(reason, 'admin', 'Bulk rejection')
        count += 1
      end
    end
    
    redirect_to admin_blogs_path, notice: "❌ #{count} blogs rejected"
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
    params.require(:blog).permit(:username, :description, :hyperlink, :rss, :is_approved, :is_online, :admin_notes)
  end
end