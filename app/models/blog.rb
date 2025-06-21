class Blog < ApplicationRecord
  has_many :posts, dependent: :destroy
  
  validates :username, :description, :hyperlink, presence: true
  validates :hyperlink, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :username, uniqueness: true
  validates :hyperlink, uniqueness: true
  validates :submitter_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :approval_status, inclusion: { in: %w[pending approved rejected] }
  
  # Submission-specific validations
  validates :submitter_name, :submitter_email, presence: true, on: :submission
  validates :description, length: { minimum: 10, maximum: 500 }, on: :submission
  
  scope :approved, -> { where(approval_status: 'approved') }
  scope :pending, -> { where(approval_status: 'pending') }
  scope :rejected, -> { where(approval_status: 'rejected') }
  scope :online, -> { where(is_online: true) }
  scope :with_rss, -> { where.not(rss: nil) }
  scope :with_recent_posts, -> { joins(:posts).where('posts.published_at > ?', 1.month.ago).distinct }
  scope :recent_submissions, -> { where('submitted_at > ?', 1.week.ago).order(submitted_at: :desc) }
  scope :needs_review, -> { pending.order(submitted_at: :asc) }
  
  # For backward compatibility
  scope :legacy_approved, -> { where(is_approved: true) }
  
  before_validation :set_submission_timestamp, on: :create, if: :user_submitted?
  before_validation :normalize_urls
  after_update :send_approval_notification, if: :saved_change_to_approval_status?
  
  def self.ransackable_attributes(auth_object = nil)
    %w[created_at description hyperlink id karma last_post_date last_post_title last_post_url rss updated_at username is_approved is_online approval_status submitted_at submitter_name submitter_email]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[posts]
  end
  
  def latest_post
    posts.recent.first
  end
  
  def posts_count
    posts.count
  end
  
  def domain
    URI.parse(hyperlink).host rescue nil
  end
  
  def rss_valid?
    return false unless rss.present?
    
    begin
      uri = URI.parse(rss)
      uri.scheme.present? && uri.host.present?
    rescue URI::InvalidURIError
      false
    end
  end
  
  # Submission workflow methods
  def user_submitted?
    submitted_at.present? || submitter_email.present?
  end
  
  def pending?
    approval_status == 'pending'
  end
  
  def approved?
    approval_status == 'approved'
  end
  
  def rejected?
    approval_status == 'rejected'
  end
  
  def approve!(admin_user = nil, notes = nil)
    update!(
      approval_status: 'approved',
      is_approved: true,
      reviewed_at: Time.current,
      reviewed_by: admin_user,
      admin_notes: notes,
      rejection_reason: nil
    )
  end
  
  def reject!(reason, admin_user = nil, notes = nil)
    update!(
      approval_status: 'rejected',
      is_approved: false,
      reviewed_at: Time.current,
      reviewed_by: admin_user,
      rejection_reason: reason,
      admin_notes: notes
    )
  end
  
  def status_badge_class
    case approval_status
    when 'approved' then 'bg-green-lt'
    when 'rejected' then 'bg-red-lt'
    when 'pending' then 'bg-yellow-lt'
    else 'bg-gray-lt'
    end
  end
  
  def days_since_submission
    return nil unless submitted_at
    
    # Handle both string and datetime formats
    submission_time = submitted_at.is_a?(String) ? Time.parse(submitted_at) : submitted_at
    ((Time.current - submission_time) / 1.day).round
  end
  
  def submitter_display_name
    submitter_name.presence || submitter_email.presence || username
  end
  
  private
  
  def set_submission_timestamp
    self.submitted_at ||= Time.current
  end
  
  def normalize_urls
    # Ensure URLs have proper protocol
    if hyperlink.present? && !hyperlink.match?(/^https?:\/\//)
      self.hyperlink = "https://#{hyperlink}"
    end
    
    if rss.present? && !rss.match?(/^https?:\/\//)
      self.rss = "https://#{rss}"
    end
  end
  
  def send_approval_notification
    # This will be implemented when we add email notifications
    # BlogSubmissionMailer.status_update(self).deliver_later if submitter_email.present?
  end
end
