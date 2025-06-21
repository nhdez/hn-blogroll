class SubmissionsController < ApplicationController
  before_action :set_blog, only: [:show]
  before_action :check_submission_rate_limit, only: [:create]
  
  def new
    @blog = Blog.new
  end
  
  def create
    @blog = Blog.new(submission_params)
    @blog.approval_status = 'pending'
    @blog.is_approved = false
    
    # Additional spam protection
    if spam_detected?
      Rails.logger.warn "Potential spam submission detected from #{request.remote_ip}: #{submission_params}"
      @blog.errors.add(:base, "Your submission could not be processed. Please try again later.")
      render :new, status: :unprocessable_entity
      return
    end
    
    # Check for duplicate submissions
    if duplicate_submission?
      @blog.errors.add(:hyperlink, "This blog has already been submitted")
      render :new, status: :unprocessable_entity
      return
    end
    
    if @blog.valid?(:submission) && @blog.save
      # Log submission
      Rails.logger.info "New blog submission: #{@blog.username || 'Anonymous'} (#{@blog.submitter_email}) - #{@blog.hyperlink}"
      
      # Try to fetch RSS feed if provided to validate it
      if @blog.rss.present?
        UpdateBlogPostsJob.perform_async(@blog.id)
      end
      
      # Track submission in session to prevent spam
      session[:last_submission_at] = Time.current
      
      redirect_to submission_path(@blog), notice: 'Thank you! Your blog has been submitted for review. You will receive an email when it is reviewed.'
    else
      # Merge validation errors from both contexts
      @blog.valid?
      render :new, status: :unprocessable_entity
    end
  end
  
  def show
    @submission_status = case @blog.approval_status
    when 'pending'
      { 
        title: 'Under Review', 
        message: 'Your blog submission is currently being reviewed by our team. We will notify you via email once a decision is made.',
        class: 'alert-warning'
      }
    when 'approved'
      { 
        title: 'Approved!', 
        message: 'Congratulations! Your blog has been approved and added to the HN Blogroll.',
        class: 'alert-success'
      }
    when 'rejected'
      { 
        title: 'Not Approved', 
        message: @blog.rejection_reason || 'Your blog submission was not approved at this time.',
        class: 'alert-danger'
      }
    end
  end
  
  def guidelines
    # Static page with submission guidelines
  end
  
  private
  
  def set_blog
    @blog = Blog.find_by!(id: params[:id])
  end
  
  def submission_params
    params.require(:blog).permit(
      :username, :description, :hyperlink, :rss,
      :submitter_name, :submitter_email
    )
  end
  
  def check_submission_rate_limit
    last_submission = session[:last_submission_at]
    if last_submission && Time.current - Time.parse(last_submission) < 10.minutes
      redirect_to new_submission_path, alert: "Please wait 10 minutes between submissions."
      return false
    end
  end
  
  def spam_detected?
    params_string = submission_params.values.join(' ').downcase
    
    # Simple spam detection patterns
    spam_patterns = [
      /casino|gambling|poker|viagra|cialis|pharmacy/,
      /make.*money.*fast|get.*rich.*quick|work.*from.*home/,
      /click.*here|visit.*now|buy.*now/,
      /free.*money|instant.*cash|guaranteed.*income/,
      /http.*bit\.ly|http.*tinyurl|http.*t\.co/  # Suspicious short URLs
    ]
    
    spam_patterns.any? { |pattern| params_string.match?(pattern) }
  end
  
  def duplicate_submission?
    # Check for existing blog with same URL or email
    Blog.exists?(hyperlink: submission_params[:hyperlink]) ||
    Blog.where(submitter_email: submission_params[:submitter_email])
        .where('submitted_at > ?', 24.hours.ago)
        .exists?
  end
end